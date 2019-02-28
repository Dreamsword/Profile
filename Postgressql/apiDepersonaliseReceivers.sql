-- This function takes an account ID and depersonalises the reciever email
-- addresses if they are not also senders.
-- It can take an optional date to depersonalise everything before that date
-- otherwise it will depersonalise all receivers before now.
DROP FUNCTION IF EXISTS "apiDepersonalizeReceivers"(INTEGER, TIMESTAMP WITH TIME ZONE, BOOLEAN);
DROP FUNCTION IF EXISTS "apiDepersonaliseReceivers"(INTEGER, TIMESTAMP WITH TIME ZONE, BOOLEAN);

CREATE OR REPLACE FUNCTION "apiDepersonaliseReceivers"(
  IN tAccountId INTEGER,
  IN tStartTime TIMESTAMP WITH TIME ZONE DEFAULT now(),
  IN tForce BOOLEAN DEFAULT FALSE,
  OUT account_id INTEGER,
  OUT receivers_depersonalised INTEGER
) RETURNS SETOF RECORD AS $$
DECLARE
  tRec RECORD;
  tRec2 RECORD;
  tDepersonalise_Reseller BOOLEAN;
  tReseller BOOLEAN;
BEGIN

  IF EXISTS (
    SELECT * FROM "mstAccount" WHERE "parentAccountId" IS NULL AND id = tAccountId
  ) THEN
    -- This account has no parent, so must be a reseller
    tReseller := TRUE;
    ELSE
    tReseller := FALSE;
  END IF;

  IF tReseller = FALSE THEN
    -- This is an account, see whether it is set to depersonalize.
    IF NOT EXISTS (
      SELECT 1 FROM "mstAccount" WHERE id=tAccountId AND de_personalise
    )
    THEN
      IF tForce THEN
        -- We are forcing depersonalisation from the reseller level onto all sub-accounts.
        UPDATE "mstAccount"
        SET de_personalise = TRUE
        WHERE id = tAccountId;
      ELSE
        RETURN;
      END IF;
    END IF;
  ELSE
    -- The accountid refers to a reseller. See whether we must depersonalise everything
    -- (tDepersonalise_Reseller==TRUE), or whether we do each account in the reseller
    -- according to the setting of its depersonalise flag.
    SELECT de_personalise INTO tDepersonalise_Reseller
    FROM "mstAccount"
    WHERE id=tAccountId;
  END IF;

  -- Get here if the account is set to depersonalise, and reseller can be be set
  -- or mixed.

  IF tReseller = FALSE THEN
    -- Process one account.
    account_id := tAccountId;
    receivers_depersonalised := 0;
    FOR tRec IN
      SELECT p.id, p.email, p.created
      FROM "mstPerson" p
      JOIN "mstReceiver" r ON p.id=r.id
      LEFT OUTER JOIN "mstSender" s ON s.id=r.id
      WHERE s.id IS NULL
        AND p."parentAccountId" = tAccountId
        AND p."created" < tStartTime
    LOOP
      UPDATE "mstPerson"
      SET email = md5(regexp_replace(tRec.email, '@.*', '')) || regexp_replace(tRec.email, '^.*@', '@')
      WHERE id = tRec.id;
      receivers_depersonalised := receivers_depersonalised + 1;
    END LOOP;
    RETURN;
  ELSE
    -- Deal with a reseller.  We will process each account in the reseller, recursively,
    -- using the code above.
    RAISE DEBUG 'Processing Reseller ID = %', tAccountId;
    FOR tRec IN
      SELECT id FROM "mstAccount" WHERE "parentAccountId" = tAccountId
    LOOP
      RAISE DEBUG 'Busy with accountID: %', tRec.id;
      FOR tRec2 IN
        SELECT * FROM "apiDepersonaliseReceivers"(tRec.id, tStartTime, tDepersonalise_Reseller)
      LOOP
        account_id := tRec2.account_id;
        receivers_depersonalised := tRec2.receivers_depersonalised;
        RETURN NEXT;
      END LOOP;
    END LOOP;
  END IF;
END;
$$ LANGUAGE plpgsql VOLATILE;

-- vim: set et sw=2 ft=PL/SQL ai:
