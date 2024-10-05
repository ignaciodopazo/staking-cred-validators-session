use aiken/collection/dict
use aiken/collection/list
use aiken/collection/pairs
use cardano/address.{Credential, Script, Inline}
use cardano/assets.{PolicyId}
use cardano/transaction.{Transaction, Datum, OutputReference}

pub type CampaignOperation {
  Create
  Support
  Close
}

validator crowdfunding_v2 {
  mint(
    _redeemer: CampaignOperation,
    own_hash: PolicyId,
    self: Transaction
  ) {
    // forward validation to withdraw purpose!

    // build own credential
    let own_cred = Script(own_hash)
    // and enforce its presence in tx withdrawals
    self.withdrawals |> pairs.has_key(own_cred)
  }

  spend(
    _datum: Option<Datum>,
    _redeemer: CampaignOperation,
    utxo: OutputReference,
    self: Transaction
  ) {
    // forward validation to withdraw purpose!

    // first, get own stake credential
    expect Some(own_input) = self.inputs
      |> list.find(fn(i) { i.output_reference == utxo })
    expect Some(own_stake_cred) = own_input.output.address.stake_credential
    expect Inline(own_cred) = own_stake_cred
    // then, enforce its presence in tx withdrawals
    self.withdrawals |> pairs.has_key(own_cred)
  }

  withdraw(
    redeemer: CampaignOperation,
    account: Credential,
    self: Transaction
  ) {
    // all validation logic is placed here now!
    expect Script(own_hash) = account

    when redeemer is {
      Create ->
        // only 1 campaign token is being minted (campaign NFT)
        // campaign NFT is paid to own script address
        True
      Support ->
        // campaign input funds < campaign output funds
        True
      Close -> {
        // enforce own tokens burning
        let own_mint =
          self.mint
            |> assets.tokens(own_hash)
            |> dict.to_pairs()
        expect [Pair(_, qty)] = own_mint
        expect qty < 0
        // no campaign NFTs are present in the outputs
        self.outputs
          |> list.all(
              fn(o) {
                  o.value
                    |> assets.tokens(own_hash)
                    |> dict.is_empty()
              },
            )
        // all campaign owners sign the transaction
        // ...
      }
    }
  }

  else(_) {
    fail
  }
}