 

pragma solidity ^0.4.18;
 

 
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
}

contract DateTime {

    function toTimestamp(uint16 year, uint8 month, uint8 day) constant returns (uint timestamp);

}

contract token {

    function balanceOf(address _owner) public constant returns (uint256 value);
    function transfer(address _to, uint256 _value) public returns (bool success);

    }

contract ICO {
    using SafeMath for uint256;
     
    enum State {
        ico,
        Successful
    }
     
    State public state = State.ico;  
    uint256 public startTime = now;  
    uint256 public rate = 1250;
    uint256 public totalRaised;  
    uint256 public totalDistributed;  
    uint256 public ICOdeadline;
    uint256 public completedAt;
    token public tokenReward;
    address public creator;
    string public version = '1';

    DateTime dateTimeContract = DateTime(0x1a6184CD4C5Bea62B0116de7962EE7315B7bcBce);

     
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(
        address _creator,
        uint256 _ICOdeadline);
    event LogContributorsPayout(address _addr, uint _amount);

    modifier notFinished() {
        require(state != State.Successful);
        _;
    }
     
    function ICO (token _addressOfTokenUsedAsReward ) public {

        creator = msg.sender;
        tokenReward = _addressOfTokenUsedAsReward;
        ICOdeadline = dateTimeContract.toTimestamp(2018,5,15);

        LogFunderInitialized(
            creator,
            ICOdeadline);
    }

     
    function contribute() public notFinished payable {

        require(msg.value > (10**10));
        
        uint256 tokenBought = 0;

        totalRaised = totalRaised.add(msg.value);

        tokenBought = msg.value.div(10 ** 10); 
        tokenBought = tokenBought.mul(rate);

         
        if (now < dateTimeContract.toTimestamp(2018,2,15)){ 

            tokenBought = tokenBought.mul(15);
            tokenBought = tokenBought.div(10);  
            require(totalDistributed.add(tokenBought) <= 100000000 * (10 ** 8)); 
        
        } else if (now < dateTimeContract.toTimestamp(2018,2,28)){

            tokenBought = tokenBought.mul(14);
            tokenBought = tokenBought.div(10);  
        
        } else if (now < dateTimeContract.toTimestamp(2018,3,15)){

            tokenBought = tokenBought.mul(13);
            tokenBought = tokenBought.div(10);  
        
        } else if (now < dateTimeContract.toTimestamp(2018,3,31)){

            tokenBought = tokenBought.mul(12);
            tokenBought = tokenBought.div(10);  
        
        } else if (now < dateTimeContract.toTimestamp(2018,4,30)){

            tokenBought = tokenBought.mul(11);
            tokenBought = tokenBought.div(10);  
        
        } else if (now < dateTimeContract.toTimestamp(2018,5,15)){

            tokenBought = tokenBought.mul(105);
            tokenBought = tokenBought.div(100);  
        
        }

        totalDistributed = totalDistributed.add(tokenBought);
        
        tokenReward.transfer(msg.sender, tokenBought);

        LogFundingReceived(msg.sender, msg.value, totalRaised);
        LogContributorsPayout(msg.sender, tokenBought);
        
        checkIfFundingCompleteOrExpired();
    }

     
    function checkIfFundingCompleteOrExpired() public {

        if(now > ICOdeadline && state!=State.Successful ) {  

            state = State.Successful;  
            completedAt = now;  

            LogFundingSuccessful(totalRaised);  
            finished();  
        }
    }

     
    function finished() public {  

        require(state == State.Successful);
        uint256 remanent = tokenReward.balanceOf(this);

        require(creator.send(this.balance));
        tokenReward.transfer(creator,remanent);

        LogBeneficiaryPaid(creator);
        LogContributorsPayout(creator, remanent);

    }

     

    function () public payable {
        
        contribute();

    }
}