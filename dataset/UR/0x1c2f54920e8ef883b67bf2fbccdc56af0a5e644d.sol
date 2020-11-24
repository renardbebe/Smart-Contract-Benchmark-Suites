 

pragma solidity ^0.4.24;

contract Basic {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Moses is Basic{

  event Attend(uint32 indexed id,string indexed attentHash);
  event PublishResult(uint32 indexed id,string indexed result,bool indexed finish);


  struct MoseEvent {
    uint32 id;
    string attendHash;
    string result;
    bool finish;
  }

  mapping (uint32 => MoseEvent) internal moseEvents;

   
  function attend(uint32 _id,string _attendHash) public onlyOwner returns (bool) {
    require(moseEvents[_id].id == uint32(0),"The event exists");
    moseEvents[_id] = MoseEvent({id:_id, attendHash:_attendHash, result: "", finish:false});
    emit Attend(_id, _attendHash);
    return true;
  }

   
  function publishResult(uint32 _id,string _result) public onlyOwner returns (bool) {
    require(moseEvents[_id].id != uint32(0),"The event not exists");
    require(!moseEvents[_id].finish,"The event has been completed");
    moseEvents[_id].result = _result;
    moseEvents[_id].finish = true;
    emit PublishResult(_id, _result, true);
    return true;
  }

   
  function showMoseEvent(uint32 _id) public view returns (uint32,string,string,bool) {
    return (moseEvents[_id].id, moseEvents[_id].attendHash,moseEvents[_id].result,moseEvents[_id].finish);
  }


}