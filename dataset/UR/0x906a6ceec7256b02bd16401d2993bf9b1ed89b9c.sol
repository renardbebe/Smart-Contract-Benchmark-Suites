 

pragma solidity 0.4.19;
 

 
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

 
contract FiatContract {
 
  function USD(uint _id) constant returns (uint256);

}

 
contract DateTimeAPI {
        
    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) constant returns (uint timestamp);

}

 
contract token {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);

}

 
contract PREVIPCCS {


    FiatContract price = FiatContract(0x8055d0504666e2B6942BeB8D6014c964658Ca591);  
     

    DateTimeAPI dateTimeContract = DateTimeAPI(0x1a6184CD4C5Bea62B0116de7962EE7315B7bcBce); 
     

    using SafeMath for uint256;
     
    enum State {
        PreVIP,
        Successful
    }
     
    State public state = State.PreVIP;  
    uint256 public startTime = dateTimeContract.toTimestamp(2018,2,13,15);  
    uint256 public PREVIPdeadline = dateTimeContract.toTimestamp(2018,2,28,15);  
    uint256 public totalRaised;  
    uint256 public totalDistributed;  
    uint256 public completedAt;  
    token public tokenReward;  
    address public creator;  
    string public campaignUrl;  
    string public version = '1';

     
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(
        address _creator,
        string _url);
    event LogContributorsPayout(address _addr, uint _amount);

    modifier notFinished() {
        require(state != State.Successful);
        _;
    }
     
    function PREVIPCCS (string _campaignUrl, token _addressOfTokenUsedAsReward) public {
        creator = msg.sender;
        campaignUrl = _campaignUrl;
        tokenReward = token(_addressOfTokenUsedAsReward);

        LogFunderInitialized(
            creator,
            campaignUrl
            );
    }

     
    function contribute() public notFinished payable {
        require(now >= startTime);
        require(msg.value >= 1 szabo);

        uint256 tokenBought;  
        uint256 tokenPrice = price.USD(0);  

        totalRaised = totalRaised.add(msg.value);  

        tokenPrice = tokenPrice.mul(36);  
        tokenPrice = tokenPrice.div(10 ** 8);  

        tokenBought = msg.value.div(tokenPrice);  
        tokenBought = tokenBought.mul(10 **10);  
        
         
        if (msg.value >= 10 ether){
            tokenBought = tokenBought.mul(123);
            tokenBought = tokenBought.div(100);  
        } else if (msg.value >= 1 ether){
            tokenBought = tokenBought.mul(11);
            tokenBought = tokenBought.div(10);  
        }

        totalDistributed = totalDistributed.add(tokenBought);  
        
        tokenReward.transfer(msg.sender,tokenBought);  
        
         
        LogFundingReceived(msg.sender, msg.value, totalRaised);
        LogContributorsPayout(msg.sender,tokenBought);

        checkIfFundingCompleteOrExpired();
    }

     
    function calculateTokens(uint256 _amountOfWei) public view returns(uint256) {
        require(_amountOfWei >= 1 szabo);
        
        uint256 tokenBought;  
        uint256 tokenPrice = price.USD(0);  

        tokenPrice = tokenPrice.mul(36);  
        tokenPrice = tokenPrice.div(10 ** 8);  

        tokenBought = _amountOfWei.div(tokenPrice);  
        tokenBought = tokenBought.mul(10 **10);  

         
        if (_amountOfWei >= 10 ether){
            tokenBought = tokenBought.mul(123);
            tokenBought = tokenBought.div(100);  
        } else if (_amountOfWei >= 1 ether){
            tokenBought = tokenBought.mul(11);
            tokenBought = tokenBought.div(10);  
        }

        return tokenBought;

    }

     
    function remainigTokens() public view returns(uint256) {
        return tokenReward.balanceOf(this);
    } 

     
    function checkIfFundingCompleteOrExpired() public {

        if(now > PREVIPdeadline && state != State.Successful){

            state = State.Successful;  
            completedAt = now;  

            LogFundingSuccessful(totalRaised);  

            finished();
        }
    }

     
    function finished() public {  
        require(state == State.Successful);  
        
        uint256 remainder = tokenReward.balanceOf(this);  

        require(creator.send(this.balance));  
        tokenReward.transfer(creator,remainder);  

        LogBeneficiaryPaid(creator);
        LogContributorsPayout(creator, remainder);

    }

     
    function claimTokens(token _address) public{
        require(state == State.Successful);  
        require(msg.sender == creator);

        uint256 remainder = _address.balanceOf(this);  
        _address.transfer(creator,remainder);  
        
    }

     
    function claimEth() public {  
        require(state == State.Successful);  
        require(msg.sender == creator);

        require(creator.send(this.balance));  
    }

     
    function () public payable {
        contribute();
    }
}