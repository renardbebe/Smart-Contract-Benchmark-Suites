 

pragma solidity ^0.4.4; 

contract Authorization {

    address internal admin;

    function Authorization() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        if(msg.sender != admin) throw;
        _;
    }
}

contract NATVCoin is Authorization {

 
 

    mapping (address => uint256) private Balances;
    mapping (address => mapping (address => uint256)) private Allowances;
    string public standard = "NATVCoin v1.0";
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public coinSupply;
    uint private balance;
    uint256 private sellPrice;
    uint256 private buyPrice;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
 
 

 
 
    function NATVCoin(address benificairyAddress) {
        admin = msg.sender;
        Balances[admin] = 3000000000000000;
        coinSupply = 3000000000000000;
        decimals = 8;
        symbol = "NATV";
        name = "Native Currency";
        beneficiary = benificairyAddress;  
        SetNATVTokenSale();
    }

 

 
 
    function totalSupply() constant returns (uint initCoinSupply) {
        return coinSupply;
    }

    function balanceOf (address _owner) constant returns (uint balance){
        return Balances[_owner];
    }

    function transfer(address _to, uint256 _value) returns (bool success){
        if(Balances[msg.sender]< _value) throw;
        if(Balances[_to] + _value < Balances[_to]) throw;
         

        Balances[msg.sender] -= _value;
        Balances[_to] += _value;

        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success){
        if(Balances[_from] < _value) throw;
        if(Balances[_to] + _value < Balances[_to]) throw;
        if(_value > Allowances[_from][msg.sender]) throw;
        Balances[_from] -= _value;
        Balances[_to] += _value;
        Allowances[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _sbalanceOfpender, uint256 _value) returns (bool success){
        Allowances[msg.sender][_sbalanceOfpender] = _value;
        Approval(msg.sender, _sbalanceOfpender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return Allowances[_owner][_spender];
    }
     
     
     

    function OBEFAC(address addr) onlyAdmin public {
        beneficiary = addr;
    } 

    function releaseTokens (address _to, uint256 _value) private returns (bool success) {

        if(Balances[admin]< _value) throw;
        if(Balances[_to] + _value < Balances[_to]) throw;
         

        Balances[admin] -= _value;
        Balances[_to] += _value;

        Transfer(admin, _to, _value);

        return true;
    }

     
     
     

    enum State {
        Fundraising,  
        Failed,  
        Successful,  
        Closed  
    }
    State private state = State.Fundraising;  

    struct Contribution {
        uint amount;  
        address contributor;
    }
    Contribution[] contributions;

    uint private totalRaised;
    uint private currentBalance;  
    uint private deadline;
    uint private completedAt;
    uint private priceInWei;  
    uint private fundingMinimumTargetInWei;
    uint private fundingMaximumTargetInWei;
    address private creator;  
    address private beneficiary;  
    string private campaignUrl;
    byte constant version = 1;

    uint256 private amountInWei=0;
    uint256 private tempTotalRasiedFunds=0;
    uint256 private actualVlaue=0;
    uint256 private refundAmount = 0;
    uint256 private fundingTokens=0;

    event LogRefund(address addr, uint amount);
    event LogFundingReceived(address addr, uint amount, uint currentTotal);  
    event LogWinnerPaid(address winnerAddress);  
    event LogFundingSuccessful(uint totalRaised);  
    event LogFunderInitialized(
    address creator,
    address beneficiary,
    string url,
    uint _fundingMaximumTargetInEther,
    uint256 deadline);

     
    modifier inState(State _state) {
        if ( now > deadline ) {
            state = State.Closed;
        }

        if (state != _state) throw;
        _;
    }

    modifier isMinimum() {
        if(msg.value < priceInWei*10) throw;
        _;
    }

    modifier inMultipleOfPrice() {
        if(msg.value%priceInWei != 0) throw;
        _;
    }

    modifier isCreator() {
        if (msg.sender != creator) throw;
        _;
    }

    modifier atEndOfLifecycle() {
        if(!((state == State.Failed || state == State.Successful) && completedAt < now)) {
            throw;
        }
        _;
    }


    function SetNATVTokenSale () private {

        creator = msg.sender;
        campaignUrl = "www.nativecurrency.com";
        fundingMinimumTargetInWei = 0 * 1 ether;
        fundingMaximumTargetInWei = 30000 * 1 ether;
        deadline = now + (46739 * 1 minutes);
        currentBalance = 0;
        priceInWei = 0.001 * 1 ether;
        LogFunderInitialized(
        creator,
        beneficiary,
        campaignUrl,
        fundingMaximumTargetInWei,
        deadline);
    }

    function contribute(address _sender)
    private
    inState(State.Fundraising) returns (uint256) {

        uint256 _value = this.balance;
        amountInWei = _value;
        tempTotalRasiedFunds = totalRaised + _value;
        actualVlaue = _value;
         
         
        if (fundingMaximumTargetInWei != 0 && tempTotalRasiedFunds > fundingMaximumTargetInWei) {
             
            refundAmount = tempTotalRasiedFunds-fundingMaximumTargetInWei;
            actualVlaue = _value-refundAmount;
        }
        contributions.push(
            Contribution({
                amount: actualVlaue,
                contributor: _sender
            })
        );

        if ( refundAmount > 0 ){
            if (!_sender.send(refundAmount)) {
                throw;
            }
            LogRefund(_sender,refundAmount);
        }

        totalRaised += actualVlaue;
        currentBalance = totalRaised;

        fundingTokens = (amountInWei * 100000000) / priceInWei;

        releaseTokens(_sender, fundingTokens);

        LogFundingReceived(_sender, actualVlaue, totalRaised);

        payOut();
        checkIfFundingCompleteOrExpired();
        return contributions.length - 1;  
    }


     
     

    function checkIfFundingCompleteOrExpired() private {

        if (fundingMaximumTargetInWei != 0 && totalRaised >= fundingMaximumTargetInWei) {
            state = State.Closed;
            LogFundingSuccessful(totalRaised);
            completedAt = now;

        } else if ( now > deadline )  {
            if(totalRaised >= fundingMinimumTargetInWei){
                state = State.Closed;
                LogFundingSuccessful(totalRaised);
                completedAt = now;
            } else{
                state = State.Failed;
                completedAt = now;
            }
        }
    }

    function payOut()
    private
    inState(State.Fundraising)
    {
        if(!beneficiary.send(this.balance)) {
            throw;
        }
        if (state == State.Successful) {
            state = State.Closed;
        }
        currentBalance = 0;
        LogWinnerPaid(beneficiary);
    }

     
     

     
    function () payable inState(State.Fundraising) isMinimum() { contribute(msg.sender); }
}