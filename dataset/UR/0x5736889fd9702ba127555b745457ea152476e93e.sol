 

pragma solidity ^0.4.18;  


 
 
contract ERC721 {
   
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public pure returns (bool);
   
   
  function totalSupply() public view returns (uint256 total);
   
   

   
   

   
   
   
   
   
}


contract DailyEtherToken is ERC721 {

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "DailyEther";  
  string public constant SYMBOL = "DailyEtherToken";  

  uint256 private ticketPrice = 0.2 ether;
  string private betTitle = "";      
  uint256 private answerID = 0;      

   
   
   
   
  bool isLocked = false;
  bool isClosed = false;

   

   
  mapping (address => uint256) private addressToBetCount;

   
  mapping (uint256 => uint256) private answerIdToParticipantsCount;

   
  address public roleAdminAddress;

   
  struct Participant {
    address user_address;
    uint256 answer_id;
  }
  Participant[] private participants;

   

   
  modifier onlyAdmin() {
    require(msg.sender == roleAdminAddress);
    _;
  }

   

  function DailyEtherToken() public {
    roleAdminAddress = msg.sender;
  }

   

   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(false);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return addressToBetCount[_owner];
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

   
  function name() public pure returns (string) {
    return NAME;
  }

  function payout(address _to) public onlyAdmin {
    _payout(_to);
  }


   
  function getParticipant(uint256 _index) public view returns (
    address participantAddress,
    uint256 participantAnswerId
  ) {
    Participant storage p = participants[_index];
    participantAddress = p.user_address;
    participantAnswerId = p.answer_id;
  }


   
   
  function closeBet(uint256 _answerId) public onlyAdmin {

     
    require(isLocked == true);

     
    require(isClosed == false);

     
    answerID = _answerId;

     
    uint256 totalPrize = uint256(SafeMath.div(SafeMath.mul((ticketPrice * participants.length), 94), 100));

     
    uint256 paymentPerParticipant = uint256(SafeMath.div(totalPrize, answerIdToParticipantsCount[_answerId]));

     
    isClosed = true;

     
    for(uint i=0; i<participants.length; i++)
    {
        if (participants[i].answer_id == _answerId) {
            if (participants[i].user_address != address(this)) {
                participants[i].user_address.transfer(paymentPerParticipant);
            }
        }
    }
  }

   
  function bet(uint256 _answerId) public payable {

     
    require(isLocked == false);

     
    require(_answerId >= 1);

     
    require(msg.value >= ticketPrice);

     
    Participant memory _p = Participant({
      user_address: msg.sender,
      answer_id: _answerId
    });
    participants.push(_p);

    addressToBetCount[msg.sender]++;

     
    answerIdToParticipantsCount[_answerId]++;
  }

   
  function getTicketPrice() public view returns (uint256 price) {
    return ticketPrice;
  }

   
  function getBetTitle() public view returns (string title) {
    return betTitle;
  }

   
   
  function setAdmin(address _newAdmin) public onlyAdmin {
    require(_newAdmin != address(0));
    roleAdminAddress = _newAdmin;
  }

   
  function initBet(uint256 _ticketPriceWei, string _betTitle) public onlyAdmin {
    ticketPrice = _ticketPriceWei;
    betTitle = _betTitle;
  }

   
  function lockBet() public onlyAdmin {
    isLocked = true;
  }

   
  function isBetLocked() public view returns (bool) {
    return isLocked;
  }

   
  function isBetClosed() public view returns (bool) {
    return isClosed;
  }

   
  function symbol() public pure returns (string) {
    return SYMBOL;
  }

   
  function totalSupply() public view returns (uint256 total) {
    return participants.length;
  }


   

   
  function _payout(address _to) private {
    if (_to == address(0)) {
      roleAdminAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

}

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}