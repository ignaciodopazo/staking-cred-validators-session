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
    _policy_id: PolicyId,
    _self: Transaction
  ) {
    when redeemer is {
      Create ->
        // only 1 campaign token is being minted (campaign NFT)
        // campaign NFT is paid to own script address
        True
      Close ->
        // N campaign NFTs are being burnt, N >= 1
        // no campaign NFTs are present in the outputs
        True
      _ ->
        False
    }
  }

  spend(
    _datum: Option<Datum>,
    redeemer: CampaignOperation,
    _utxo: OutputReference,
    _self: Transaction
  ) {
    when redeemer is {
      Support ->
        True
      Close ->
        // enforce campaign NFT burning (at least 1) --> THIS RUNS N TIMES, WITH N THE QUANTITY OF CAMPAIGNS BEING CLOSED!!!
        // campaign owner signs the transaction
        True
      _ ->
        False
    }
  }

  else(_) {
    fail
  }
}