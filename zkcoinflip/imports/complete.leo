program complete.aleo {
  record complete_record {
    owner: address;
    gates: u64;
    issuer_number: u64;
    issuer: address;
    acceptor: address;
    winner: address;
  }

  transition create_complete(
    private acceptor: address,
    private acceptor_seed: u64,
    private issuer_seed: u64,
    private winner: address
    ) -> (complete_record, complete_record) {
    let issuer_complete_record: complete_record = complete_record {
      owner: self.caller,
      gates: 0u64,
      issuer_number: issuer_seed,
      issuer: self.caller,
      acceptor: acceptor,
      winner: winner
    };

    let acceptor_complete_record: complete_record = complete_record {
      owner: acceptor,
      gates: 0u64,
      issuer_number: issuer_seed,
      issuer: self.caller,
      acceptor: acceptor,
      winner: winner
    };

    return (issuer_complete_record, acceptor_complete_record);
  }
}