 

pragma solidity 0.4.23;
 

 
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


 
contract DateTime {

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public constant returns (uint timestamp);

}


 
contract manager {
    address public admin;  
    
     
    constructor() internal {
        admin = msg.sender;  
        emit Manager(admin);
    }

     
    modifier onlyAdmin() {  
        require(msg.sender == admin);
        _;
    }

     
    function transferAdminship(address _newAdmin) onlyAdmin public {  
        admin = _newAdmin;
        emit TransferAdminship(admin);
    }

     
    event TransferAdminship(address newAdminister);
    event Manager(address administer);

}

contract IADTGE is manager {

    using SafeMath for uint256;

    DateTime dateTimeContract = DateTime(0x1a6184CD4C5Bea62B0116de7962EE7315B7bcBce); 
    
     
    enum State {
        Ongoing,
        Successful
    }
     
    token public constant tokenReward = token(0xC1E2097d788d33701BA3Cc2773BF67155ec93FC4);
    State public state = State.Ongoing;  
    uint256 public startTime = dateTimeContract.toTimestamp(2018,4,30,7,0);  
    uint256 public deadline = dateTimeContract.toTimestamp(2018,5,31,6,59);  
    uint256 public totalRaised;  
    uint256 public totalDistributed;  
    uint256 public completedAt;
    address public creator;
    uint256[2] public rates = [6250,5556]; 
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

     
    function contribute() public notFinished payable {
        require(now >= startTime);
        uint256 tokenBought;

        totalRaised = totalRaised.add(msg.value);

        if (now < startTime.add(15 days)){

            tokenBought = msg.value.mul(rates[0]);
        
        } else {

            tokenBought = msg.value.mul(rates[1]);
        
        }

        totalDistributed = totalDistributed.add(tokenBought);
        
        tokenReward.transfer(msg.sender, tokenBought);

        emit LogFundingReceived(msg.sender, msg.value, totalRaised);
        emit LogContributorsPayout(msg.sender, tokenBought);
        
        checkIfFundingCompleteOrExpired();
    }

     
    function checkIfFundingCompleteOrExpired() public {

        if(now > deadline){

            state = State.Successful;  
            completedAt = now;  

            emit LogFundingSuccessful(totalRaised);  
            finished();  

        }
    }

     
    function finished() public {  

        require(state == State.Successful);
        uint256 remanent = tokenReward.balanceOf(this);

        require(creator.send(address(this).balance));
        tokenReward.transfer(creator,remanent);

        emit LogBeneficiaryPaid(creator);
        emit LogContributorsPayout(creator, remanent);

    }

     
    function claimTokens(token _address) onlyAdmin public{
        require(state == State.Successful);  

        uint256 remainder = _address.balanceOf(this);  
        _address.transfer(admin,remainder);  
        
    }

     

    function () public payable {
        
        contribute();

    }
}