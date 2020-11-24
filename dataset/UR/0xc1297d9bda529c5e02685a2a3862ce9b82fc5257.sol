 

pragma solidity ^0.4.2;

contract Geocache {
  struct VisitorLog {
    address visitor;
    string name;
    string dateTime;  
    string location;  
    string note;
    string imageUrl;
  }

  VisitorLog[] public visitorLogs;

   
  function createLog(string _name, string _dateTime, string _location, string _note, string _imageUrl) public {
    visitorLogs.push(VisitorLog(msg.sender, _name, _dateTime, _location, _note, _imageUrl));
  }

   
  function getNumberOfLogEntries() public view returns (uint) {
    return visitorLogs.length;
  }

   
  function setFirstLogEntry() public {
    require(msg.sender == 0x8d3e809Fbd258083a5Ba004a527159Da535c8abA);
    visitorLogs.push(VisitorLog(0x0, "Mythical Geocache Creator", "2018-08-31T12:00:00", "[50.0902822,14.426874199999997]", "I was here first", " " ));
  }
}