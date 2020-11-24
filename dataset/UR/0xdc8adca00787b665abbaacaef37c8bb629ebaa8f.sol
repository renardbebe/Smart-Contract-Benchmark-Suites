 

pragma solidity ^0.4.18;


contract TopIvy {

   
  string public constant NAME = "TopIvy";
  uint256 public constant voteCost = 0.001 ether;
  
   
  string public constant schoolOrdering = "BrownColumbiaCornellDartmouthHarvardPennPrincetonYale";

   
  address public ceoAddress;
  uint256[8] public voteCounts = [1,1,1,1,1,1,1,1];

   
   
   
   
   
   
   
   
   

   
   
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

   
  function TopIvy() public {
    ceoAddress = msg.sender;
  }

   
   
   
  function payout(address _to) public onlyCEO{
    _payout(_to);
  }

   
   
  function buyVotes(uint8 _id) public payable {
       
      require(msg.value >= voteCost);
       
      require(_id >= 0 && _id <= 7);
       
      uint256 votes = msg.value / voteCost;
      voteCounts[_id] += votes;
       
  }

   
   
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));
    ceoAddress = _newCEO;
  }
  
   
  function getVotes() public view returns(uint256[8]) {
      return voteCounts;
  }

   
   
  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }
}