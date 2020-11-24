 

pragma solidity ^0.4.23;

 

 
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

 

 
contract ERC20TokenInterface {

    function balanceOf(address _owner) public constant returns (uint256 value);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

}

 

 
contract FiatContractInterface {

    function EUR(uint _id) public constant returns (uint256);

}

 

 
contract NETRico {

    FiatContractInterface price = FiatContractInterface(0x8055d0504666e2B6942BeB8D6014c964658Ca591);  

    using SafeMath for uint256;

     
    enum State {
        Stage1,
        Stage2,
        Successful
    }

     
    State public state = State.Stage1;  
    uint256 public startTime;
    uint256 public startStage2Time;
    uint256 public deadline;
    uint256 public totalRaised;  
    uint256 public totalDistributed;  
    uint256 public completedAt;  
    ERC20TokenInterface public tokenReward;  
    address public creator;  
    string public campaignUrl;  
    string public version = "2";

     
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(address _creator, string _url);
    event LogContributorsPayout(address _addr, uint _amount);

    modifier notFinished() {
        require(state != State.Successful);
        _;
    }

    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }

     
    function NETRico(string _campaignUrl, ERC20TokenInterface _addressOfTokenUsedAsReward,
        uint256 _startTime, uint256 _startStage2Time, uint256 _deadline) public {
        require(_addressOfTokenUsedAsReward != address(0)
            && _startTime > now
            && _startStage2Time > _startTime
            && _deadline > _startStage2Time);

        creator = 0xB987B463c7573f0B7b6eD7cc8E5Fab9042272065;
         
        campaignUrl = _campaignUrl;
        tokenReward = ERC20TokenInterface(_addressOfTokenUsedAsReward);

        startTime = _startTime;
        startStage2Time = _startStage2Time;
        deadline = _deadline;

        emit LogFunderInitialized(creator, campaignUrl);
    }

     
    function() public payable {
        contribute();
    }

     
    function setStage2Start(uint256 _startStage2Time) public onlyCreator {
        require(_startStage2Time > now && _startStage2Time > startTime && _startStage2Time < deadline);
        startStage2Time = _startStage2Time;
    }

     
    function setDeadline(uint256 _deadline) public onlyCreator {
        require(_deadline > now && _deadline > startStage2Time);
        deadline = _deadline;
    }

     
    function contribute() public notFinished payable {
        require(now >= startTime);

        uint256 tokenBought;
         
        uint256 tokenPrice = price.EUR(0);
         

        totalRaised = totalRaised.add(msg.value);
         

        tokenPrice = tokenPrice.mul(2);
         
        tokenPrice = tokenPrice.div(10 ** 8);
         

        tokenBought = msg.value.div(tokenPrice);
         
        tokenBought = tokenBought.mul(10 ** 10);
         

        require(tokenBought >= 100 * 10 ** 18);
         

         
        if (state == State.Stage1) {
            tokenBought = tokenBought.mul(140);
            tokenBought = tokenBought.div(100);
             
        } else if (state == State.Stage2) {
            tokenBought = tokenBought.mul(120);
            tokenBought = tokenBought.div(100);
             
        }

        totalDistributed = totalDistributed.add(tokenBought);
         

        tokenReward.transfer(msg.sender, tokenBought);
         

        creator.transfer(msg.value);
         
        emit LogBeneficiaryPaid(creator);

         
        emit LogFundingReceived(msg.sender, msg.value, totalRaised);
        emit LogContributorsPayout(msg.sender, tokenBought);

        checkIfFundingCompleteOrExpired();
    }

     
    function checkIfFundingCompleteOrExpired() public {

        if (now > deadline && state != State.Successful) {

            state = State.Successful;
             
            completedAt = now;
             

            emit LogFundingSuccessful(totalRaised);
             

            finished();
        } else if (state == State.Stage1 && now >= startStage2Time) {

            state = State.Stage2;

        }
    }

     
    function finished() public {  
        require(state == State.Successful);
         

        uint256 remainder = tokenReward.balanceOf(this);
         
         
        if (address(this).balance > 0) {
            creator.transfer(address(this).balance);
            emit LogBeneficiaryPaid(creator);
        }

        tokenReward.transfer(creator, remainder);
         
        emit LogContributorsPayout(creator, remainder);

    }

     
    function claimTokens(ERC20TokenInterface _address) public {
        require(state == State.Successful);
         
        require(msg.sender == creator);

        uint256 remainder = _address.balanceOf(this);
         
        _address.transfer(creator, remainder);
         

    }
}