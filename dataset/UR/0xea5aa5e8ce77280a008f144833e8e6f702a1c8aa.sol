 

pragma solidity ^0.4.16;
 
library SafeMath {

    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract token {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);

    }

contract ICO {
    using SafeMath for uint256;
     
    enum State {
        Ongoin,
        SoftCap,
        Successful
    }
     
    State public state = State.Ongoin;  
    uint256 public startTime = now;  
    uint256 public delay;
     
    uint[2] public tablePrices = [
    2500,  
    2000
    ];
    uint256 public SoftCap = 40000000 * (10 ** 18);  
    uint256 public HardCap = 80000000 * (10 ** 18);  
    uint256 public totalRaised;  
    uint256 public totalDistributed;  
    uint256 public ICOdeadline = startTime.add(21 days); 
    uint256 public completedAt;
    uint256 public closedAt;
    token public tokenReward;
    address public creator;
    address public beneficiary;
    string public campaignUrl;
    uint8 constant version = 1;

     
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(
        address _creator,
        address _beneficiary,
        string _url,
        uint256 _ICOdeadline);
    event LogContributorsPayout(address _addr, uint _amount);

    modifier notFinished() {
        require(state != State.Successful);
        _;
    }
     
    function ICO (string _campaignUrl, token _addressOfTokenUsedAsReward, uint256 _delay) public {
        creator = msg.sender;
        beneficiary = msg.sender;
        campaignUrl = _campaignUrl;
        tokenReward = token(_addressOfTokenUsedAsReward);
        delay = startTime.add(_delay * 1 hours);
        LogFunderInitialized(
            creator,
            beneficiary,
            campaignUrl,
            ICOdeadline);
    }

     
    function contribute() public notFinished payable {
        require(now > delay);
        uint tokenBought;
        totalRaised = totalRaised.add(msg.value);

        if(totalDistributed < 10000000 * (10 ** 18)){  
            tokenBought = msg.value.mul(tablePrices[0]);
        }
        else {
            tokenBought = msg.value.mul(tablePrices[1]);
        }

        totalDistributed = totalDistributed.add(tokenBought);
        tokenReward.transfer(msg.sender, tokenBought);
        
        LogFundingReceived(msg.sender, msg.value, totalRaised);
        LogContributorsPayout(msg.sender, tokenBought);
        
        checkIfFundingCompleteOrExpired();
    }

     
    function checkIfFundingCompleteOrExpired() public {
        
        if(now < ICOdeadline && state!=State.Successful){  
            if(state == State.Ongoin && totalRaised >= SoftCap){  
                state = State.SoftCap;  
                completedAt = now;  
            }
            else if (state == State.SoftCap && now > completedAt.add(24 hours)){  
                state == State.Successful;  
                closedAt = now;  
                LogFundingSuccessful(totalRaised);  
                finished();  
            }
        }
        else if(now > ICOdeadline && state!=State.Successful ) {  
            state = State.Successful;  

            if(completedAt == 0){   
                completedAt = now;  
            }

            closedAt = now;  
            LogFundingSuccessful(totalRaised);  
            finished();  
        }
    }

    function payOut() public {
        require(msg.sender == beneficiary);
        require(beneficiary.send(this.balance));
        LogBeneficiaryPaid(beneficiary);
    }

    
    function finished() public {  
        require(state == State.Successful);
        uint256 remanent = tokenReward.balanceOf(this);

        require(beneficiary.send(this.balance));
        tokenReward.transfer(beneficiary,remanent);

        LogBeneficiaryPaid(beneficiary);
        LogContributorsPayout(beneficiary, remanent);
    }

    function () public payable {
        contribute();
    }
}