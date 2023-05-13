import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import Error "mo:base/Error";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Timer "mo:base/Timer";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";

import IC "Ic";
import HTTP "Http";
import Type "Types";

actor class Verifier() {
  type StudentProfile = Type.StudentProfile;
  stable var studentEntries : [(Principal, StudentProfile)] = [];

  //let studentProfileBkp = Array<(Principal,StudentProfile)>[];
  let studentProfileStore = HashMap.HashMap<Principal, StudentProfile>(1, Principal.equal, Principal.hash);

  system func preupgrade() {
    studentEntries := Iter.toArray(studentProfileStore.entries());
  };

  system func postupgrade() {
    for ((studentId, profile) in studentEntries.vals()) {
      studentProfileStore.put(studentId, profile);
    };
  };

  // STEP 1 - BEGIN
  public shared ({ caller }) func addMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    studentProfileStore.put(caller, profile);
    return #ok;
  };

  public shared ({ caller }) func seeAProfile(p : Principal) : async Result.Result<StudentProfile, Text> {
    switch (studentProfileStore.get(p)) {
      case (null) {
        return #err("Student profile not found.");
      };
      case (?profile) {
        return #ok(profile);
      };
    };

  };

  public shared ({ caller }) func updateMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    switch (studentProfileStore.get(caller)) {
      case (null) {
        return #err("Student profile not found.");
      };
      case (_) {
        studentProfileStore.put(caller, profile);
        return #ok;
      };
    };
  };

  public shared ({ caller }) func deleteMyProfile() : async Result.Result<(), Text> {
    switch (studentProfileStore.get(caller)) {
      case (null) {
        return #err("Student profile not found.");
      };
      case (_) {
        studentProfileStore.delete(caller);
        return #ok;
      };
    };
  };
  // STEP 1 - END

  // STEP 2 - BEGIN
  type calculatorInterface = Type.CalculatorInterface;
  public type TestResult = Type.TestResult;
  public type TestError = Type.TestError;

  public func test(canisterId : Principal) : async TestResult {
    let calculatorActor = actor (Principal.toText(canisterId)) : actor {
      add : shared (Int) -> async Int;
      sub : shared (Nat) -> async Int;
      reset : shared () -> async Int;
    };

    //Testing Calculator.Reset()
    try {
      ignore await calculatorActor.add(2);
      let value = await calculatorActor.reset();
      if (value != 0) {
        return #err(#UnexpectedValue("Reset method has an error."));
      };
    } catch (e) {
      return #err(#UnexpectedError("An error occured when calling canister calculatorActor.reset"));
    };
    //Testing Calculator.add()
    try {
      ignore await calculatorActor.reset();
      let value = await calculatorActor.add(2);
      if (value != 2) {
        return #err(#UnexpectedValue("Add method has an error."));
      };
    } catch (e) {
      return #err(#UnexpectedError("An error occured when calling canister calculatorActor.add"));
    };

    //Testing Calculator.sub()
    try {
      ignore await calculatorActor.reset();
      ignore await calculatorActor.add(2);
      let value = await calculatorActor.sub(2);
      if (value != 0) {
        return #err(#UnexpectedValue("Sub method has an error."));
      };
    } catch (e) {
      return #err(#UnexpectedError("An error occured when calling canister calculatorActor.sub"));
    };

    return #ok;
  };
  // STEP - 2 END

  // STEP 3 - BEGIN
  // NOTE: Not possible to develop locally,
  // as actor "aaaa-aa" (aka the IC itself, exposed as an interface) does not exist locally
    func parseControllersFromCanisterStatusErrorIfCallerNotController(errorMessage : Text) : [Principal] {
        let lines = Iter.toArray(Text.split(errorMessage, #text("\n")));
        let words = Iter.toArray(Text.split(lines[1], #text(" ")));
        var i = 2;
        let controllers = Buffer.Buffer<Principal>(0);
        while (i < words.size()) {
            controllers.add(Principal.fromText(words[i]));
            i += 1;
        };
        Buffer.toArray<Principal>(controllers);
    };

    public func verifyOwnership(canisterId : Principal, p : Principal) : async Bool {
        let managementCanister : IC.ManagementCanisterInterface = actor ("aaaaa-aa");
        try {
            let canisterStatus = await managementCanister.canister_status({
                canister_id = canisterId;
            });
            let canisterControllers = canisterStatus.settings.controllers;
            for (controller in canisterControllers.vals()) {
                if (controller == p) {
                    return true;
                };
            };
            return false;
        } catch (e) {
            let message = Error.message(e);
            let controlers = parseControllersFromCanisterStatusErrorIfCallerNotController(message);
            for (controller in controlers.vals()) {
                if (controller == p) {
                    return true;
                };
            };
            return false;
        };
    };
  // STEP 3 - END

  // STEP 4 - BEGIN
  public shared ({ caller }) func verifyWork(canisterId : Principal, p : Principal) : async Result.Result<(), Text> {
    try {
      let isOwner = await verifyOwnership(canisterId, p);
      if (isOwner) {
        switch (_getTestResult(await test(canisterId))) {
          case (#ok) {
            switch (studentProfileStore.get(p)) {
              case (null) {
                return #err("The principalId: " #Principal.toText(p) # " profile not found. ");
              };
              case (?profile) {
                let graduatedProfile = {
                  name = profile.name;
                  team = profile.team;
                  graduate = true;
                };
                studentProfileStore.put(p, graduatedProfile);
              };
            };

            return #ok;
          };
          case (#err(errorMessage)) {
            return #err(errorMessage);
          };
        };

      } else {
        return #err("The principalId: " #Principal.toText(p) # " is not the owner of canistedId: " # Principal.toText(canisterId) # ".");
      };
    } catch (e) {
      return #err("An error occured when calling canister bootcamptActor");
    };
  };

  func _getTestResult(result : TestResult) : Result.Result<(), Text> {
    switch (result) {
      case (#ok) {
        return #ok;
      };
      case (#err(errorType)) {
        switch (errorType) {
          case (#UnexpectedValue(errorMessage)) {
            return #err(errorMessage);
          };
          case (#UnexpectedError(errorMessage)) {
            return #err(errorMessage);
          };
        };
      };
    };
  };

  // STEP 4 - END

};
