 

pragma solidity ^0.4.15;

 
contract PlayToken {
    uint256 public totalSupply = 0;
    string public name = "PLAY";
    uint8 public decimals = 18;
    string public symbol = "PLY";
    string public version = '1';

    address public controller;
    bool public controllerLocked = false;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    modifier onlyController() {
        require(msg.sender == controller);
        _;
    }

     
    function PlayToken(address _controller) {
        controller = _controller;
    }

     
    function setController(address _newController) onlyController {
        require(! controllerLocked);
        controller = _newController;
    }

     
    function lockController() onlyController {
        controllerLocked = true;
    }

     
    function mint(address _receiver, uint256 _value) onlyController {
        balances[_receiver] += _value;
        totalSupply += _value;
         
        Transfer(0, _receiver, _value);
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
         
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

     
    function withdrawTokens(ITransferable _token, address _to, uint256 _amount) onlyController {
        _token.transfer(_to, _amount);
    }
}

 
contract P4PPool {
    address public owner;
    PlayToken public playToken;

    uint8 public currentState = 0;
     
    uint8 public constant STATE_NOT_STARTED = 0;
    uint8 public constant STATE_DONATION_ROUND_1 = 1;
    uint8 public constant STATE_PLAYING = 2;
    uint8 public constant STATE_DONATION_ROUND_2 = 3;
    uint8 public constant STATE_PAYOUT = 4;

    uint256 public tokenPerEth;  

    mapping(address => uint256) round1Donations;
    mapping(address => uint256) round2Donations;

     
    uint256 public totalPhase1Donations = 0;
    uint256 public totalPhase2Donations = 0;

     
    uint32 public donationUnlockTs = uint32(now);  

     
    uint8 public constant ownerTokenSharePct = 20;

    address public donationReceiver;
    bool public donationReceiverLocked = false;

    event StateChanged(uint8 newState);
    event DonatedEthPayout(address receiver, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyDuringDonationRounds() {
        require(currentState == STATE_DONATION_ROUND_1 || currentState == STATE_DONATION_ROUND_2);
        _;
    }

    modifier onlyIfPayoutUnlocked() {
        require(currentState == STATE_PAYOUT);
        require(uint32(now) >= donationUnlockTs);
        _;
    }

     
    function P4PPool(address _tokenAddr) {
        owner = msg.sender;
        playToken = PlayToken(_tokenAddr);
    }

     
    function () payable onlyDuringDonationRounds {
        donateForImpl(msg.sender);
    }

     
    function donateFor(address _donor) payable onlyDuringDonationRounds {
        donateForImpl(_donor);
    }

    function startNextPhase() onlyOwner {
        require(currentState <= STATE_PAYOUT);
        currentState++;
        if(currentState == STATE_PAYOUT) {
             
            tokenPerEth = calcTokenPerEth();
        }
        StateChanged(currentState);
    }

    function setDonationUnlockTs(uint32 _newTs) onlyOwner {
        require(_newTs > donationUnlockTs);
        donationUnlockTs = _newTs;
    }

    function setDonationReceiver(address _receiver) onlyOwner {
        require(! donationReceiverLocked);
        donationReceiver = _receiver;
    }

    function lockDonationReceiver() onlyOwner {
        require(donationReceiver != 0);
        donationReceiverLocked = true;
    }

     
    function payoutDonations() onlyOwner onlyIfPayoutUnlocked {
        require(donationReceiver != 0);
        var amount = this.balance;
        require(donationReceiver.send(amount));
        DonatedEthPayout(donationReceiver, amount);
    }

     
    function destroy() onlyOwner {
        require(currentState == STATE_PAYOUT);
        require(now > 1519862400);
        selfdestruct(owner);
    }

     
    function withdrawTokenShare() {
        require(tokenPerEth > 0);  
        require(playToken.transfer(msg.sender, calcTokenShareOf(msg.sender)));
        round1Donations[msg.sender] = 0;
        round2Donations[msg.sender] = 0;
    }

     

    function calcTokenShareOf(address _addr) constant internal returns(uint256) {
        if(_addr == owner) {
             
            var virtualEthBalance = (((totalPhase1Donations*2 + totalPhase2Donations) * 100) / (100 - ownerTokenSharePct) + 1);
            return ((tokenPerEth * virtualEthBalance) * ownerTokenSharePct) / (100 * 1E18);
        } else {
            return (tokenPerEth * (round1Donations[_addr]*2 + round2Donations[_addr])) / 1E18;
        }
    }

     
    function calcTokenPerEth() constant internal returns(uint256) {
        var tokenBalance = playToken.balanceOf(this);
         
         
         
        var virtualEthBalance = (((totalPhase1Donations*2 + totalPhase2Donations) * 100) / (100 - ownerTokenSharePct) + 1);
         
        return tokenBalance * 1E18 / (virtualEthBalance);
    }

    function donateForImpl(address _donor) internal onlyDuringDonationRounds {
        if(currentState == STATE_DONATION_ROUND_1) {
            round1Donations[_donor] += msg.value;
            totalPhase1Donations += msg.value;
        } else if(currentState == STATE_DONATION_ROUND_2) {
            round2Donations[_donor] += msg.value;
            totalPhase2Donations += msg.value;
        }
    }
}