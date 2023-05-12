import TrieMap "mo:base/TrieMap";
import Trie "mo:base/Trie";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Account "Account";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Array "mo:base/Array";

// NOTE: only use for local dev,
// when deploying to IC, import from "rww3b-zqaaa-aaaam-abioa-cai"
import BootcampLocalActor "BootcampLocalActor";

//import service "local:canister_id";

actor class MotoCoin() {
  public type Account = Account.Account;
  let ledger = TrieMap.TrieMap<Account, Nat>(Account.accountsEqual, Account.accountsHash);
  let BOOTCAMP_CANISTER_ID_LOCAL = "bd3sg-teaaa-aaaaa-qaaba-cai";
  let BOOTCAMP_CANISTER_ID_IC = "rww3b-zqaaa-aaaam-abioa-cai";
 
  //let CANISTED_ID = BOOTCAMP_CANISTER_ID_LOCAL;
  let CANISTED_ID = BOOTCAMP_CANISTER_ID_IC;

  let bootcamptActor = actor(CANISTED_ID) : actor {
    getAllStudentsPrincipal : shared () -> async [Principal];
};

  // Returns the name of the token
  public query func name() : async Text {
    return "MotoCoin";
  };

  // Returns the symbol of the token
  public query func symbol() : async Text {
    return "MOC";
  };

  // Returns the the total number of tokens on all accounts
  public func totalSupply() : async Nat {
    var totalSupply = 0;
    for (supply in ledger.vals()) {
      totalSupply += supply;
    };
    return totalSupply;
  };

  // Returns the default transfer fee
  public query func balanceOf(account : Account) : async (Nat) {
    return _balanceOf(account);
  };

  // Transfer tokens to another account
  public shared ({ caller }) func transfer(from : Account, to : Account, amount : Nat) : async Result.Result<(), Text> {
    let fromAccountBalance = _balanceOf(from);
    if(amount == 0){
      return #err("The amount to transfer can't be 0.");
    };
    if (amount > fromAccountBalance) {
      return #err("Not enough token to transfer.");
    };
    _decreaseAccountBalance(from,amount);
    _increaseAccountBalance(to,amount);
    return #ok;
  };

  // Airdrop 1000 MotoCoin to any student that is part of the Bootcamp.
  public func airdrop() : async Result.Result<(), Text> {
     try {
      let bootcampStudentsPrincipals = await bootcamptActor.getAllStudentsPrincipal();    
      for(principal in bootcampStudentsPrincipals.vals()){
        let account ={
          owner = principal;
          subaccount = null;
        };
        _increaseAccountBalance(account,100);
      };
      return #ok;
     }catch(e){
        return #err("An error occured when calling canister bootcamptActor");
     }
      
  };


  public query func showAllBalances() : async ([(Account,Nat)]) {
    return Iter.toArray(ledger.entries());
  };

  public func increaseAccountBalance(account : Account, amount : Nat) : async () {
    var accountBalance = _balanceOf(account);
    ledger.put(account, accountBalance +amount);
  };

  private func _increaseAccountBalance(account : Account, amount : Nat) {
    var accountBalance = _balanceOf(account);
    ledger.put(account, accountBalance +amount);
  };

  private func _decreaseAccountBalance(account : Account, amount : Nat) {
    var accountBalance = _balanceOf(account);
    ledger.put(account, accountBalance-amount);
  };

  private func _balanceOf(account : Account) : Nat {
    switch (ledger.get(account)) {
      case (null) {
        return 0;
      };
      case (?supply) {
        return supply;
      };
    };
  };

};
