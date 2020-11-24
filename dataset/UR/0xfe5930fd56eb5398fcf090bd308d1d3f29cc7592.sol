 

pragma solidity 0.4.25;
 

 
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

}


 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public;
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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

contract PRIWGRICO is admined {

    using SafeMath for uint256;
     
    enum State {
        MAINSALE,
        Successful
    }
     

     
    State public state = State.MAINSALE;  
    uint256 public MAINSALEStart = now;
    uint256 public SaleDeadline = MAINSALEStart.add(120 days);  
    uint256 public completedAt;  
     
    uint256 public totalRaised;  
    uint256 public totalDistributed;  
    ERC20Basic public tokenReward;  

     
    address public creator;  
    address public WGRholder;  
    string public version = '0.1';  

     
    uint256 public USDPriceInWei;  

     
    event LogFundrisingInitialized(address indexed _creator);
    event LogFundingReceived(address indexed _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address indexed _beneficiaryAddress);
    event LogContributorsPayout(address indexed _addr, uint _amount);
    event LogFundingSuccessful(uint _totalRaised);

     
    modifier notFinished() {
        require(state != State.Successful);
        _;
    }

     
    constructor(ERC20Basic _addressOfTokenUsedAsReward, uint _initialUSDInWei) public {

        creator = msg.sender;  
        WGRholder = creator;  
        tokenReward = _addressOfTokenUsedAsReward;  
        USDPriceInWei = _initialUSDInWei;

        emit LogFundrisingInitialized(creator);  

    }

     
    function contribute(address _target, uint256 _value) public notFinished payable {
        require(now > MAINSALEStart);  

        address user;
        uint remaining;
        uint256 tokenBought;
        uint256 temp;

        if(_target != address(0) && level[msg.sender] >= 1){
          user = _target;
          remaining = _value.mul(1e18);
        } else {
          user = msg.sender;
          remaining = msg.value.mul(1e18);
        }

        totalRaised = totalRaised.add(remaining.div(1e18));  

        while(remaining > 0){

          (temp,remaining) = tokenBuyCalc(remaining);
          tokenBought = tokenBought.add(temp);

        }

        temp = 0;

        totalDistributed = totalDistributed.add(tokenBought);  
        
        WGRholder.transfer(address(this).balance);  
        emit LogBeneficiaryPaid(WGRholder);  

        tokenReward.transfer(user,tokenBought);

        emit LogFundingReceived(user, msg.value, totalRaised);  

        checkIfFundingCompleteOrExpired();  
    }


     
    function tokenBuyCalc(uint _value) internal view returns (uint sold,uint remaining) {

      uint256 tempPrice = USDPriceInWei;  

       

      tempPrice = tempPrice.mul(1000);  
      sold = _value.div(tempPrice);

      return (sold,0);

    }

     
    function checkIfFundingCompleteOrExpired() public {

        if ( now > SaleDeadline && state != State.Successful){  

            state = State.Successful;  
            completedAt = now;  

            emit LogFundingSuccessful(totalRaised);  
            successful();  

        }

    }

     
    function successful() public {
        require(state == State.Successful);  
        uint256 temp = tokenReward.balanceOf(address(this));  
        tokenReward.transfer(creator,temp);  

        emit LogContributorsPayout(creator,temp);  

        WGRholder.transfer(address(this).balance);  

        emit LogBeneficiaryPaid(WGRholder);  

    }

     
    function setPrice(uint _value) public onlyAdmin(2) {

      USDPriceInWei = _value;

    }
    function setHolder(address _holder) public onlyAdmin(2) {

      WGRholder = _holder;

    }

     
    function externalTokensRecovery(ERC20Basic _address) onlyAdmin(2) public{
        require(state == State.Successful);  

        uint256 remainder = _address.balanceOf(address(this));  
        _address.transfer(msg.sender,remainder);  

    }

     
    function () public payable {

        contribute(address(0),0);  

    }
}