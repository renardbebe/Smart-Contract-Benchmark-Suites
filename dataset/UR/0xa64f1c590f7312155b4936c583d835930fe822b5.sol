 

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

 
interface ERC20Basic {
    function totalSupply() constant external returns (uint256 supply);
    function balanceOf(address _owner) constant external returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

 
contract admined {
    mapping(address => uint8) public level;
     
     
     
     

     
    constructor() internal {
        level[msg.sender] = 2;  
        emit AdminshipUpdated(msg.sender,2);
    }

     
    modifier onlyAdmin(uint8 _level) {  
        require(level[msg.sender] >= _level );
        _;
    }

     
    function adminshipLevel(address _newAdmin, uint8 _level) onlyAdmin(2) public {  
        require(_newAdmin != address(0));
        level[_newAdmin] = _level;
        emit AdminshipUpdated(_newAdmin,_level);
    }

     
    event AdminshipUpdated(address _newAdmin, uint8 _level);

}

contract ROCICO is admined {

    using SafeMath for uint256;
     
    enum State {
        Stage1,
        Stage2,
        Stage3,
        Successful
    }
     

     
    State public state = State.Stage1;  
    uint256 public startTime = 1536969600;  
    uint256 public Stage1Deadline = 1538308800;  
    uint256 public Stage2Deadline = 1539604800;  
    uint256 public Stage3Deadline = 1540943999;  
    uint256 public completedAt;  

     
    uint256 public totalRaised;  
    uint256 public totalDistributed;  
    ERC20Basic public tokenReward;  

     
    address public creator;
    address public beneficiary;
    string public version = '1';

     
    uint256[3] rates = [1000000,800000,700000];

     
    event LogFundrisingInitialized(address _creator);
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogContributorsPayout(address _addr, uint _amount);
    event LogFundingSuccessful(uint _totalRaised);

     
    modifier notFinished() {
        require(state != State.Successful);
        _;
    }

     
    constructor(address _beneficiaryAddress) public {

        require(_beneficiaryAddress != address(0));

        beneficiary = _beneficiaryAddress;
        creator = msg.sender;  
        tokenReward = ERC20Basic(0x7872b3f20268Eb85120430Cf9abfEEa01F95A91c);  

        emit LogFundrisingInitialized(beneficiary);
    }

     
    function contribute() public notFinished payable {

        require(now >= startTime);

         
        require(msg.value >= 1 finney);

        uint256 tokenBought = 0;  

        totalRaised = totalRaised.add(msg.value);  

        emit LogFundingReceived(msg.sender, msg.value, totalRaised);  

        if(state == State.Stage1){

            tokenBought = msg.value.mul(rates[0]);  

             
            tokenBought = tokenBought.mul(125);
            tokenBought = tokenBought.div(100);

        } else if(state == State.Stage2){

            tokenBought = msg.value.mul(rates[1]);  

             
            tokenBought = tokenBought.mul(115);
            tokenBought = tokenBought.div(100);

        } else {

            tokenBought = msg.value.mul(rates[2]);  

             
            tokenBought = tokenBought.mul(105);
            tokenBought = tokenBought.div(100);

        }

        tokenBought = tokenBought.div(1e10);  

        totalDistributed = totalDistributed.add(tokenBought);  

        require(tokenReward.transfer(msg.sender,tokenBought));

        emit LogContributorsPayout(msg.sender,tokenBought);  

        checkIfFundingCompleteOrExpired();  
    }

     
    function checkIfFundingCompleteOrExpired() public {

        if( now >= Stage3Deadline && state != State.Successful ){ 

            state = State.Successful;  
            completedAt = now;  

            emit LogFundingSuccessful(totalRaised);  
            successful();  

        } else if (state == State.Stage1 && now >= Stage1Deadline){

            state = State.Stage2;

        } else if (state == State.Stage2 && now >= Stage2Deadline){

            state = State.Stage3;

        }
    }

     
    function successful() public {
         
        require(state == State.Successful);

         
        uint256 remanent = tokenReward.balanceOf(this);  
        require(tokenReward.transfer(beneficiary,remanent)); 

         
        beneficiary.transfer(address(this).balance);
        emit LogBeneficiaryPaid(creator);
    }

     
    function externalTokensRecovery(ERC20Basic _address) onlyAdmin(2) public{

        require(state == State.Successful);

        uint256 remainder = _address.balanceOf(this);  
        _address.transfer(msg.sender,remainder);  

    }

     
    function () public payable {

        contribute();

    }
}