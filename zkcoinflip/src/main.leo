import issue.leo;
import accept.leo;
import complete.leo;

// The 'zkcoinflip' program.
program zkcoinflip.aleo {
    transition issue_challenge(
      private input_seed: u64,
      private acceptor_address: address
      ) -> issue.leo/issue_record.record {
      let input_seed_as_field: field = Poseidon4::hash(input_seed);
      let issued_record: issue_record = issue.leo/create_issue(input_seed_as_field, acceptor_address);
      return issued_record;
    }

    transition accept_challenge(
      private acceptor_seed: u64,
      private issued_record: issue.leo/issue_record.record
      ) -> accept.leo/accept_record.record {
      let accepted_record: accept_record
        = accept.leo/create_accept(issued_record.issuer, issued_record.hashed_issuer_seed, acceptor_seed);

      return accepted_record;
    }

    transition complete_challenge(
      private original_issuer_seed: u64,
      private accepted_record: accept.leo/accept_record.record
      ) -> (complete.leo/complete_record.record, complete.leo/complete_record.record) {
      let input_seed_as_field: field = Poseidon4::hash(original_issuer_seed);
      assert_eq(input_seed_as_field, accepted_record.hashed_issuer_seed);

      let added: u64 = original_issuer_seed + accepted_record.acceptor_seed;
      let remainder: u64 = added % 2u64;

      let winner: address = remainder == 1u64 ? self.caller : accepted_record.acceptor;

      let (issuer_complete_record, acceptor_complete_record): (complete_record, complete_record)
        = complete.leo/create_complete(accepted_record.acceptor, accepted_record.acceptor_seed, original_issuer_seed, winner);

      return (issuer_complete_record, acceptor_complete_record);
    }
}
