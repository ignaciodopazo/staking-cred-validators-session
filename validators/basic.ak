use cardano/transaction.{Redeemer, Transaction}
use cardano/address.{Credential}
use cardano/certificate.{Certificate}

validator basic {
  // validates the delegation of own stake credential
  publish(_r: Redeemer, _cert: Certificate, _self: Transaction) {
    True
  }

  // validates the staking rewards withdrawals of own stake credential
  withdraw(_r: Redeemer, _account: Credential, _self: Transaction) {
    True
  }

  else(_) {
    fail
  }
}