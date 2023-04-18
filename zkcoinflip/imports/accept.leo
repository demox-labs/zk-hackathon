program accept.aleo {
  record accept_record {
    owner: address;
    gates: u64;
    hashed_issuer_seed: field;
    acceptor_seed: u64;
    acceptor: address;
  }

  transition create_accept(
    private issuer: address,
    private issuer_seed: field,
    private acceptor_seed: u64
    ) -> accept_record {
    return accept_record {
      owner: issuer,
      gates: 0u64,
      hashed_issuer_seed: issuer_seed,
      acceptor_seed: acceptor_seed,
      acceptor: self.caller
    };
  }
}