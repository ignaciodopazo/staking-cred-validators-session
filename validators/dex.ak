use aiken/crypto.{VerificationKeyHash}
use aiken/collection/list
use aiken/collection/pairs
use cardano/address.{Credential, Script}
use cardano/assets.{PolicyId, quantity_of, lovelace_of}
use cardano/certificate.{Certificate, RegisterCredential, DelegateCredential}
use cardano/transaction.{Transaction, Redeemer, Datum, OutputReference}

// the pool is parameterized by the admin public key
// admin signature is needed in privileged operations
validator dex(admin_key: VerificationKeyHash) {
  mint(_redeemer: Redeemer, _policy_id: PolicyId, _self: Transaction) {
    // suppose the ADA/DJED pool is a UTxO containing:
    // - X ADA
    // - Y DJED
    // - 1 pool NFT
    // where X, Y > 0
    // the pool NFT is minted in this mint action. This NFT will identify the pool
    True
  }

  spend(_datum: Option<Datum>, _redeemer: Redeemer, _utxo: OutputReference, _self: Transaction) {
    // here will go the rules that the pool UTxO must satisfy for the protocol sanity
    True
  }

  // for publishing the certificate and for delegating to a specific stake pool
  publish(_r: Redeemer, cert: Certificate, self: Transaction) {
    when cert is {
      // anyone can register the stake credential of the pool. no security issues here
      // even more, if someone else does it is doing a favour since this costs some ADA
      RegisterCredential { .. } -> True

      // the protocol admin decides to which stake pool
      // the ADA/DJED pool funds will be delegated
      DelegateCredential { .. } ->
        self.extra_signatories |> list.has(admin_key)

      // we don't care about other actions
      _ -> False
    }
  }

  // validates the staking rewards withdrawals of own stake credential
  // spec: all the withdrawn ADA must go to the pool UTxO
  withdraw(_r: Redeemer, account: Credential, self: Transaction) {
    expect Script(own_hash) = account
    // the pool NFT has the same hash as this stake credential validator,
    //   since both are into the same validator, this one!!
    // so, we search for the pool UTxO in the inputs,
    expect Some(pool_input) =
      self.inputs
        |> list.find(
          fn (input) {
            let pool_nft_qty =
              input.output.value
                |> quantity_of(
                  policy_id: own_hash,
                  asset_name: "admin",
                )
            pool_nft_qty == 1
          })
    // search for the pool UTxO in the outputs,
    expect Some(pool_output) =
      self.outputs
        |> list.find(
          fn (output) {
            let pool_nft_qty =
              output.value
                |> quantity_of(
                  policy_id: own_hash,
                  asset_name: "admin",
                )
            pool_nft_qty == 1
          })
    // and lookup their ADA amount.
    let pool_input_lovelace_amount = pool_input.output.value |> lovelace_of()
    let pool_output_lovelace_amount = pool_output.value |> lovelace_of()

    // finally, lookup what's the withdrawn amount
    expect Some(amount_withdrawn) =
      self.withdrawals |> pairs.get_first(account)

    // and check that all that amount goes to the pool output
    pool_input_lovelace_amount + amount_withdrawn == pool_output_lovelace_amount
  }

  else(_) {
    fail
  }
}