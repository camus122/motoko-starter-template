import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Bool "mo:base/Bool";
import Debug "mo:base/Debug";

actor class Homework() {
  type Time = Time.Time;

  type Homework = {
    title : Text;
    description : Text;
    dueDate : Time;
    completed : Bool;
  };

  let homeworkDiary = Buffer.Buffer<Homework>(0);

  public shared func reset() : async () {
    homeworkDiary.clear();
  };

  // Add a new homework task
  public shared func addHomework(homework : Homework) : async Nat {
    let index=homeworkDiary.size();
    homeworkDiary.add(homework);
    return index;
  };

  /* Get a specific homework task by id
  4- Implement getHomework, which accepts a homeworkId of type Nat,
     and returns the corresponding homework wrapped in an Ok result.
     If the homeworkId is invalid, the function should return an error message wrapped in an Err result.
  */
  public query func getHomework(id : Nat) : async Result.Result<Homework, Text> {
    if (id >= homeworkDiary.size()) {
      return #err("Homework id not found");
    } else {
      return #ok(homeworkDiary.get(id));
    };
  };

  // Update a homework task's title, description, and/or due date
  public shared func updateHomework(id : Nat, homework : Homework) : async Result.Result<(), Text> {
    let homeworkOpt : ?Homework = homeworkDiary.getOpt(id);
    switch (homeworkOpt) {
      case (null) {
        return #err("Homework id not found");
      };
      case (_) {
        homeworkDiary.put(id, homework);
        return #ok();
      };
    };
  };

  // Mark a homework task as completed
  public shared func markAsCompleted(id : Nat) : async Result.Result<(), Text> {
    let homeworkOpt : ?Homework = homeworkDiary.getOpt(id);
    switch (homeworkOpt) {
      case (null) {
        return #err("Homework id not found");
      };
      case (?homework) {
        let newHomework : Homework = {
          title = homework.title;
          description = homework.description;
          dueDate = homework.dueDate;
          completed = true;
        };
        homeworkDiary.put(id, newHomework);
        return #ok();
      };
    };
  };

  // Delete a homework task by id
  public shared func deleteHomework(id : Nat) : async Result.Result<(), Text> {
    let homeworkOpt : ?Homework = homeworkDiary.getOpt(id);
    switch (homeworkOpt) {
      case (null) {
        return #err("Homework id not found");
      };
      case (_) {
        ignore homeworkDiary.remove(id);
        return #ok();
      };
    };
  };

  // Get the list of all homework tasks
  public shared query func getAllHomework() : async [Homework] {
    return Buffer.toArray<Homework>(homeworkDiary);
  };

  // Get the list of pending (not completed) homework tasks
  public shared query func getPendingHomework() : async [Homework] {
    let pendingHomework = Buffer.mapFilter<Homework, Homework>(homeworkDiary, func (x) {
      if (x.completed == false) {
        ?x;
      } else {
        null;
      }
    });
    return Buffer.toArray<Homework>(pendingHomework);
  };

  // Search for homework tasks based on a search terms
  public shared query func searchHomework(searchTerm : Text) : async [Homework] {
    let searchHomework = Buffer.mapFilter<Homework, Homework>(homeworkDiary, func (x) {
      if(Text.contains(x.title, #text searchTerm) or Text.contains(x.description, #text searchTerm)){
         ?x;
      }else{
        null;
      }
    });
    return Buffer.toArray<Homework>(searchHomework);
  };

};
