import Type "Types";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Hash "mo:base/Hash";
import Principal "mo:base/Principal";
import Int "mo:base/Int";

actor class StudentWall() {
  type Message = Type.Message;
  type Content = Type.Content;
  type Survey = Type.Survey;
  type Answer = Type.Answer;

  var messageId : Nat = 0;
  let wall = HashMap.HashMap<Nat, Message>(1, Nat.equal, Hash.hash);

  // Add a new message to the wall
  public shared ({ caller }) func writeMessage(c : Content) : async Nat {
    let message = {
      content = c;
      vote = 0;
      creator = caller;
    };
    wall.put(messageId, message);
    let messageIdBkp=messageId;
    _increaseMessageId();
    return messageIdBkp;
  };

  // Get a specific message by ID
  public shared query func getMessage(messageId : Nat) : async Result.Result<Message, Text> {
    return _getMessage(messageId);
  };

  //Obtener mensajge
  private func _getMessage(messageId : Nat) : Result.Result<Message, Text> {
    switch (wall.get(messageId)) {
      case (null) {
        return #err("MessageId '" # Nat.toText(messageId) # "'' not found.");
      };
      case (?message) {
        return #ok(message);
      };
    };
  };

  private func _isMessageOwner(caller : Principal, message : Message) : Bool {
    return message.creator == caller;
  };

  // Update the content for a specific message by ID
  public shared ({ caller }) func updateMessage(messageId : Nat, c : Content) : async Result.Result<(), Text> {
    switch (_getMessage(messageId)) {
      case (#err(error)) {
        return #err(error);
      };
      case (#ok(message)) {
        if (_isMessageOwner(caller, message)) {
          let updatedMessage = {
            content = c;
            vote = message.vote;
            creator = message.creator;
          };
          wall.put(messageId, updatedMessage);
          return #ok;
        } else {
          return #err("You're not the owner of messageId: " # Nat.toText(messageId) # "(" # Principal.toText(caller) # ")");
        };

      };
    };
  };

  // Delete a specific message by ID
  public shared ({ caller }) func deleteMessage(messageId : Nat) : async Result.Result<(), Text> {
    switch (_getMessage(messageId)) {
      case (#err(error)) {
        return #err(error);
      };
      case (#ok(message)) {
        wall.delete(messageId);
        _decreaseMessageId();
        return #ok;
      };
    };
  };

  // Voting
  public func upVote(messageId : Nat) : async Result.Result<(), Text> {
    switch (_getMessage(messageId)) {
      case (#err(error)) {
        return #err(error);
      };
      case (#ok(message)) {
        let updatedMessage = {
          content = message.content;
          vote = message.vote +1;
          creator = message.creator;
        };
        wall.put(messageId, updatedMessage);
        return #ok;
      };
    };
  };

  public func downVote(messageId : Nat) : async Result.Result<(), Text> {
    switch (_getMessage(messageId)) {
      case (#err(error)) {
        return #err(error);
      };
      case (#ok(message)) {
        let updatedMessage = {
          content = message.content;
          vote = message.vote -1;
          creator = message.creator;
        };
        wall.put(messageId, updatedMessage);
        return #ok;
      };
    };
  };

  // Get all messages
  public func getAllMessages() : async [Message] {
    return Iter.toArray(wall.vals());
  };



  // Get all messages ordered by votes
  public func getAllMessagesRanked() : async [Message] {
    let sortedMessages=Iter.sort<Message>(wall.vals(),func(x,y)= Int.compare(y.vote, x.vote));
    return Iter.toArray(sortedMessages);
  };

  //private
  private func _increaseMessageId() {
    messageId += 1;
  };

  private func _decreaseMessageId() {
    messageId -= 1;
  };
};
