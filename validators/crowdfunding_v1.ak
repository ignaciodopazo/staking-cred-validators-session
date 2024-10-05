use aiken/collection/dict
use aiken/collection/list
use cardano/address.{Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{Transaction, Datum, OutputReference}

pub type CampaignOperation {
  Create
  Support
  Close
}

validator crowdfunding_v1 {
  mint(
    redeemer: CampaignOperation,
    own_hash: PolicyId,
    self: Transaction
  ) {
    when redeemer is {
      Create ->
        // only 1 campaign token is being minted (campaign NFT)
        // campaign NFT is paid to own script address
        True
      Close -> {
        // only burning allowed
        let own_mint =
          self.mint
            |> assets.tokens(own_hash)
            |> dict.to_pairs()
        expect [Pair(_, qty)] = own_mint
        expect qty < 0
        // no own tokens in outputs
        self.outputs
          |> list.all(
              fn(o) {
                  o.value
                    |> assets.tokens(own_hash)
                    |> dict.is_empty()
              },
            )
      }
      _ ->
        False
    }
  }

  spend(
    _datum: Option<Datum>,
    redeemer: CampaignOperation,
    utxo: OutputReference,
    self: Transaction
  ) {
    when redeemer is {
      Support ->
        // campaign input funds < campaign output funds
        True
      Close -> {
        // enforce campaign NFT burning (at least 1)
        //   get own hash
        expect Some(own_input) = self.inputs
          |> list.find(fn(i) { i.output_reference == utxo })
        expect Script(own_hash) = own_input.output.address.payment_credential
        //   get own tokens minting
        let own_mint =
          self.mint
            |> assets.tokens(own_hash)
            |> dict.to_pairs()
        expect [Pair(_, qty)] = own_mint
        //    only burning allowed
        expect qty < 0
        // campaign owner sign the transaction
        // ...
        True
      }
      _ ->
        False
    }
  }

  else(_) {
    fail
  }
}