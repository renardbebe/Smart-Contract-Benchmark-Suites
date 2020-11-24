 

pragma solidity 0.4.24;
 

 
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

 
contract token {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public;

}


 
contract admined {
    mapping (address => uint8) public admin;  

     
    constructor() internal {
        admin[msg.sender] = 2;  
        emit AssignAdminship(msg.sender, 2);
    }

     
    modifier onlyAdmin(uint8 _level) {  
        require(admin[msg.sender] >= _level);
        _;
    }

     
    function assingAdminship(address _newAdmin, uint8 _level) onlyAdmin(2) public {  
        admin[_newAdmin] = _level;
        emit AssignAdminship(_newAdmin , _level);
    }

     
    event AssignAdminship(address newAdminister, uint8 level);

}

contract IADSpecialEvent is admined {

    using SafeMath for uint256;

     
    enum State {
        Ongoing,
        Successful
    }
     
    token public constant tokenReward = token(0xC1E2097d788d33701BA3Cc2773BF67155ec93FC4);
    State public state = State.Ongoing;  
    uint256 public totalRaised;  
    uint256 public totalDistributed;  
    uint256 public completedAt;
    address public creator;
    mapping (address => bool) whiteList;
    uint256 public rate = 6250; 
    string public version = '1';

     
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(address _creator);
    event LogContributorsPayout(address _addr, uint _amount);

    modifier notFinished() {
        require(state != State.Successful);
        _;
    }

     
    constructor () public {

        creator = msg.sender;

        emit LogFunderInitialized(creator);
    }

     
    function whitelistAddress(address _user, bool _flag) onlyAdmin(1) public {
        whiteList[_user] = _flag;
    }

    function checkWhitelist(address _user) onlyAdmin(1) public view returns (bool flag) {
        return whiteList[_user];
    }

     
    function contribute() public notFinished payable {
         
        require(whiteList[msg.sender] == true);
         
        uint256 tokenBought = msg.value.mul(rate);
         
        require(tokenBought >= 150000 * (10 ** 18));
         
        totalRaised = totalRaised.add(msg.value);
         
        totalDistributed = totalDistributed.add(tokenBought);
         
        tokenReward.transfer(msg.sender, tokenBought);
         
        emit LogFundingReceived(msg.sender, msg.value, totalRaised);
        emit LogContributorsPayout(msg.sender, tokenBought);
    }

     
    function finish() onlyAdmin(2) public {  

        if(state != State.Successful){
          state = State.Successful;
          completedAt = now;
        }

        uint256 remanent = tokenReward.balanceOf(this);
        require(creator.send(address(this).balance));
        tokenReward.transfer(creator,remanent);

        emit LogBeneficiaryPaid(creator);
        emit LogContributorsPayout(creator, remanent);

    }

    function sendTokensManually(address _to, uint256 _amount) onlyAdmin(2) public {

        require(whiteList[_to] == true);
         
        totalDistributed = totalDistributed.add(_amount);
         
        tokenReward.transfer(_to, _amount);
         
        emit LogContributorsPayout(_to, _amount);

    }

     
    function claimETH() onlyAdmin(2) public{

        require(creator.send(address(this).balance));

        emit LogBeneficiaryPaid(creator);

    }

     
    function claimTokens(token _address) onlyAdmin(2) public{
        require(state == State.Successful);  

        uint256 remainder = _address.balanceOf(this);  
        _address.transfer(msg.sender,remainder);  

    }

     

    function () public payable {

        contribute();

    }
}