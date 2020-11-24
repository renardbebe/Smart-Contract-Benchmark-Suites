 

pragma solidity ^0.4.18;


library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal returns (uint) {
         
        uint c = a / b;
         
        return c;
    }

    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

}
contract Ownable {
    address public owner;


     
    function Ownable() {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

}
contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
}
contract ROKToken is ERC20, Ownable {
    using SafeMath for uint256;

    string public constant name = "ROK Token";
    string public constant symbol = "ROK";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 100000000000000000000000000;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

     
    function ROKToken() {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }


     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function unlockTransfer(address _spender, uint256 _value) public returns (bool) {

    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function burn(uint256 _value) public returns (bool success){
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
        return true;
    }
}
contract Pausable is Ownable {
    event Pause();

    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

     
    function unpause() onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}
contract PullPayment {
    using SafeMath for uint256;

    mapping (address => uint256) public payments;

    uint256 public totalPayments;

     
    function asyncSend(address dest, uint256 amount) internal {
        payments[dest] = payments[dest].add(amount);
        totalPayments = totalPayments.add(amount);
    }

     
    function withdrawPayments() {
        address payee = msg.sender;
        uint256 payment = payments[payee];

        require(payment != 0);
        require(this.balance >= payment);

        totalPayments = totalPayments.sub(payment);
        payments[payee] = 0;

        assert(payee.send(payment));
    }
}

 

contract Crowdsale is Pausable, PullPayment {
    using SafeMath for uint256;

    address public owner;
    ROKToken public rok;
    address public escrow;                                                              
    address public bounty ;                                                             
    address public team;                                                                
    uint256 public rateETH_ROK;                                                         
    uint256 public constant minimumPurchase = 0.1 ether;                                
    uint256 public constant maxFundingGoal = 100000 ether;                              
    uint256 public constant minFundingGoal = 18000 ether;                               
    uint256 public constant startDate = 1509534000;                                     
    uint256 public constant deadline = 1512126000;                                      
    uint256 public constant refundeadline = 1515927600;                                 
    uint256 public savedBalance = 0;                                                    
    uint256 public savedBalanceToken = 0;                                               
    bool public crowdsaleclosed = false;                                                
    mapping (address => uint256) balances;                                              
    mapping (address => uint256) balancesRokToken;                                      
    mapping (address => bool) KYClist;

     
    event Contribution(address indexed _contributor, uint256 indexed _value, uint256 indexed _tokens);

     
    event PayEther(
    address indexed _receiver,
    uint256 indexed _value,
    uint256 indexed _timestamp
    );

     
    event BurnTokens(
    uint256 indexed _value,
    uint256 indexed _timestamp
    );

     
    function Crowdsale(){
        owner = msg.sender;
         
        rok = ROKToken(0xc9de4b7f0c3d991e967158e4d4bfa4b51ec0b114);
        escrow = 0x049ca649c977ec36368f31762ff7220db0aae79f;
        bounty = 0x50Cc6F2D548F7ecc22c9e9F994E4C0F34c7fE8d0;
        team = 0x33462171A814d4eDa97Cf3a112abE218D05c53C2;
        rateETH_ROK = 1000;
    }


     
     
     
    function() payable whenNotPaused{
        if (msg.sender == escrow){
            balances[this] = msg.value;
        }
        else{
            contribute(msg.sender);
        }
    }

     
    function contribute(address contributor) internal{
        require(isStarted());
        require(!isComplete());
        assert((savedBalance.add(msg.value)) <= maxFundingGoal);
        assert(msg.value >= minimumPurchase);
        balances[contributor] = balances[contributor].add(msg.value);
        savedBalance = savedBalance.add(msg.value);
        uint256 Roktoken = rateETH_ROK.mul(msg.value) + getBonus(rateETH_ROK.mul(msg.value));
        uint256 RokToSend = (Roktoken.mul(80)).div(100);
        balancesRokToken[contributor] = balancesRokToken[contributor].add(RokToSend);
        savedBalanceToken = savedBalanceToken.add(Roktoken);
        escrow.transfer(msg.value);
        PayEther(escrow, msg.value, now);
    }


     
    function isStarted() constant returns (bool) {
        return now >= startDate;
    }

     
    function isComplete() constant returns (bool) {
        return (savedBalance >= maxFundingGoal) || (now > deadline) || (savedBalanceToken >= rok.totalSupply()) || (crowdsaleclosed == true);
    }

     
    function tokenBalance() constant returns (uint256 balance) {
        return rok.balanceOf(address(this));
    }

     
    function isSuccessful() constant returns (bool) {
        return (savedBalance >= minFundingGoal);
    }

     
    function checkEthBalance(address _contributor) constant returns (uint256 balance) {
        return balances[_contributor];
    }

     
    function checkRokSold() constant returns (uint256 total) {
        return (savedBalanceToken);
         
    }

     
    function checkRokTeam() constant returns (uint256 totalteam) {
        return (savedBalanceToken.mul(19).div(100));
         
    }

     
    function checkRokBounty() constant returns (uint256 totalbounty) {
        return (savedBalanceToken.div(100));
    }

     
    function refundPeriodOver() constant returns (bool){
        return (now > refundeadline);
    }

     
    function refundPeriodStart() constant returns (bool){
        return (now > deadline);
    }

     
    function percentOfGoal() constant returns (uint16 goalPercent) {
        return uint16((savedBalance.mul(100)).div(minFundingGoal));
    }

     
    function getBonus(uint256 amount) internal constant returns (uint256) {
        uint bonus = 0;
         
        uint firstbonusdate = 1509879600;
         
        uint secondbonusdate = 1510311600;

         
        if (now <= firstbonusdate) {bonus = amount.div(10);}
         
        else if (now <= secondbonusdate && now >= firstbonusdate) {bonus = amount.div(20);}
         
        return bonus;
    }

     
    function setBalance(address sender,uint256 value) internal{
        balances[sender] = value;
    }

     
    function finalize() onlyOwner {
        require(isStarted());
        require(!isComplete());
        crowdsaleclosed = true;
    }

     
    function payout() onlyOwner {
        if (isSuccessful() && isComplete()) {
            rok.transfer(bounty, checkRokBounty());
            payTeam();
        }
        else {
            if (refundPeriodOver()) {
                escrow.transfer(savedBalance);
                PayEther(escrow, savedBalance, now);
                rok.transfer(bounty, checkRokBounty());
                payTeam();
            }
        }
    }

     
    function payTeam() internal {
        assert(checkRokTeam() > 0);
        rok.transfer(team, checkRokTeam());
        if (checkRokSold() < rok.totalSupply()) {
             
            rok.burn(rok.totalSupply().sub(checkRokSold()));
             
            BurnTokens(rok.totalSupply().sub(checkRokSold()), now);
        }
    }

     
    function updateKYClist(address[] allowed) onlyOwner{
        for (uint i = 0; i < allowed.length; i++) {
            if (KYClist[allowed[i]] == false) {
                KYClist[allowed[i]] = true;
            }
        }
    }

     
    function claim() public{
        require(isComplete());
        require(checkEthBalance(msg.sender) > 0);
        if(checkEthBalance(msg.sender) <= (3 ether)){
            rok.transfer(msg.sender,balancesRokToken[msg.sender]);
            balancesRokToken[msg.sender] = 0;
        }
        else{
            require(KYClist[msg.sender] == true);
            rok.transfer(msg.sender,balancesRokToken[msg.sender]);
            balancesRokToken[msg.sender] = 0;
        }
    }

     
    function refund() public {
        require(!isSuccessful());
        require(refundPeriodStart());
        require(!refundPeriodOver());
        require(checkEthBalance(msg.sender) > 0);
        uint ETHToSend = checkEthBalance(msg.sender);
        setBalance(msg.sender,0);
        asyncSend(msg.sender, ETHToSend);
    }

     
    function partialRefund(uint256 value) public {
        require(!isSuccessful());
        require(refundPeriodStart());
        require(!refundPeriodOver());
        require(checkEthBalance(msg.sender) >= value);
        setBalance(msg.sender,checkEthBalance(msg.sender).sub(value));
        asyncSend(msg.sender, value);
    }

}