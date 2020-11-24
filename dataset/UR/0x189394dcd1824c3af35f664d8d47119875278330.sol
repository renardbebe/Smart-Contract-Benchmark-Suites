 

 

pragma solidity ^0.4.24;

contract yolecoin {   
    string public constant name         = "yolecoin";
    string public constant symbol       = "yole";
    uint public constant decimals       = 18;
    
    uint256 yoleEthRate                  = 10 ** decimals;
    uint256 yoleSupply                   = 1000000000;
    uint256 public totalSupply           = yoleSupply * yoleEthRate;
    uint256 public freezeDuration        = 30 days;

    bool public running                 = true;  
    
    address owner;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public whitelist;
    mapping (address =>  uint256) whitelistLimit;

    struct BalanceInfo {
        uint256 balance;
        uint256[] freezeAmount;
        uint256[] releaseTime;
    }
    mapping (address => BalanceInfo) balances;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event BeginRunning();
    event PauseRunning();
    event BeginSell();
    event PauseSell();
    event Burn(address indexed burner, uint256 val);
    event Freeze(address indexed from, uint256 value);
    
    constructor () public{
        owner = msg.sender;
        balances[owner].balance = totalSupply;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyWhitelist() {
        require(whitelist[msg.sender] == true);
        _;
    }
    
    modifier isRunning(){
        require(running);
        _;
    }
    modifier isNotRunning(){
        require(!running);
        _;
    }

     
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

        
    function transferOwnership(address _newOwner) onlyOwner public {
        if (_newOwner !=    address(0)) {
            owner = _newOwner;
        }
    }
    
    function pause() onlyOwner isRunning    public   {
        running = false;
        emit PauseRunning();
    }
    
    function start() onlyOwner isNotRunning public   {
        running = true;
        emit BeginRunning();
    }

    function airDeliver(address _to,    uint256 _amount)  onlyOwner public {
        require(owner != _to);
        require(_amount > 0);
        require(balances[owner].balance >= _amount);
        
         
        if(_amount < yoleSupply){
            _amount = _amount * yoleEthRate;
        }
        balances[owner].balance = safeSub(balances[owner].balance, _amount);
        balances[_to].balance = safeAdd(balances[_to].balance, _amount);
        emit Transfer(owner, _to, _amount);
    }
    
    
    function airDeliverMulti(address[]  _addrs, uint256 _amount) onlyOwner public {
        require(_addrs.length <=  255);
        
        for (uint8 i = 0; i < _addrs.length; i++)   {
            airDeliver(_addrs[i],   _amount);
        }
    }
    
    function airDeliverStandalone(address[] _addrs, uint256[] _amounts) onlyOwner public {
        require(_addrs.length <=  255);
        require(_addrs.length ==     _amounts.length);
        
        for (uint8 i = 0; i < _addrs.length;    i++) {
            airDeliver(_addrs[i],   _amounts[i]);
        }
    }

 
    function  freezeDeliver(address _to, uint _amount, uint _freezeAmount, uint _freezeMonth, uint _unfreezeBeginTime ) onlyOwner public {
        require(owner != _to);
        require(_freezeMonth > 0);
        
        uint average = _freezeAmount / _freezeMonth;
        BalanceInfo storage bi = balances[_to];
        uint[] memory fa = new uint[](_freezeMonth);
        uint[] memory rt = new uint[](_freezeMonth);

        if(_amount < yoleSupply){
            _amount = _amount * yoleEthRate;
            average = average * yoleEthRate;
            _freezeAmount = _freezeAmount * yoleEthRate;
        }
        require(balances[owner].balance > _amount);
        uint remainAmount = _freezeAmount;
        
        if(_unfreezeBeginTime == 0)
            _unfreezeBeginTime = now + freezeDuration;
        for(uint i=0;i<_freezeMonth-1;i++){
            fa[i] = average;
            rt[i] = _unfreezeBeginTime;
            _unfreezeBeginTime += freezeDuration;
            remainAmount = safeSub(remainAmount, average);
        }
        fa[i] = remainAmount;
        rt[i] = _unfreezeBeginTime;
        
        bi.balance = safeAdd(bi.balance, _amount);
        bi.freezeAmount = fa;
        bi.releaseTime = rt;
        balances[owner].balance = safeSub(balances[owner].balance, _amount);
        emit Transfer(owner, _to, _amount);
        emit Freeze(_to, _freezeAmount);
    }
    
    function  freezeDeliverMuti(address[] _addrs, uint _deliverAmount, uint _freezeAmount, uint _freezeMonth, uint _unfreezeBeginTime ) onlyOwner public {
        require(_addrs.length <=  255);
        
        for(uint i=0;i< _addrs.length;i++){
            freezeDeliver(_addrs[i], _deliverAmount, _freezeAmount, _freezeMonth, _unfreezeBeginTime);
        }
    }

    function  freezeDeliverMultiStandalone(address[] _addrs, uint[] _deliverAmounts, uint[] _freezeAmounts, uint _freezeMonth, uint _unfreezeBeginTime ) onlyOwner public {
        require(_addrs.length <=  255);
        require(_addrs.length == _deliverAmounts.length);
        require(_addrs.length == _freezeAmounts.length);
        
        for(uint i=0;i< _addrs.length;i++){
            freezeDeliver(_addrs[i], _deliverAmounts[i], _freezeAmounts[i], _freezeMonth, _unfreezeBeginTime);
        }
    }
    
    function addWhitelist(address[] _addrs) public onlyOwner {
        require(_addrs.length <=  255);

        for (uint8 i = 0; i < _addrs.length; i++) {
            if (!whitelist[_addrs[i]]){
                whitelist[_addrs[i]] = true;
            }
        }
    }

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner].balance;
    }
    
    function freezeOf(address _owner) constant  public returns (uint256) {
        BalanceInfo storage bi = balances[_owner];
        uint freezeAmount = 0;
        uint t = now;
        
        for(uint i=0;i< bi.freezeAmount.length;i++){
            if(t < bi.releaseTime[i])
                freezeAmount += bi.freezeAmount[i];
        }
        return freezeAmount;
    }
    
    function transfer(address _to, uint256 _amount)  isRunning onlyPayloadSize(2 *  32) public returns (bool success) {
        require(_to != address(0));
        uint freezeAmount = freezeOf(msg.sender);
        uint256 _balance = safeSub(balances[msg.sender].balance, freezeAmount);
        require(_amount <= _balance);
        
        balances[msg.sender].balance = safeSub(balances[msg.sender].balance,_amount);
        balances[_to].balance = safeAdd(balances[_to].balance,_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) isRunning onlyPayloadSize(3 * 32) public returns (bool   success) {
        require(_from   != address(0) && _to != address(0));
        require(_amount <= allowed[_from][msg.sender]);
        uint freezeAmount = freezeOf(_from);
        uint256 _balance = safeSub(balances[_from].balance, freezeAmount);
        require(_amount <= _balance);
        
        balances[_from].balance = safeSub(balances[_from].balance,_amount);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_amount);
        balances[_to].balance = safeAdd(balances[_to].balance,_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function approve(address _spender, uint256 _value) isRunning public returns (bool   success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { 
            return  false; 
        }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function withdraw() onlyOwner public {
        address myAddress = this;
        require(myAddress.balance > 0);
        owner.transfer(myAddress.balance);
        emit Transfer(this, owner, myAddress.balance);    
    }
    
    function burn(address burner, uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender].balance);

        balances[burner].balance = safeSub(balances[burner].balance, _value);
        totalSupply = safeSub(totalSupply, _value);
        yoleSupply = totalSupply / yoleEthRate;
        emit Burn(burner, _value);
    }
}