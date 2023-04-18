program issue.aleo {
  record issue_record {
      owner: address;
      gates: u64;
      hashed_issuer_seed: field;
      issuer: address;
  }

  transition create_issue(
    private hashed_seed: field,
    private acceptor: address
    ) -> issue_record {
    return issue_record {
      owner: acceptor,
      gates: 0u64,
      hashed_issuer_seed: hashed_seed,
      issuer: self.caller
    };
  }
}