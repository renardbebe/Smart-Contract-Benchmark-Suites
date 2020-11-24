 

pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

 
contract ERC_20_2 {
     
    string public name; 
     
    string public symbol;
     
    uint8 public decimals;
     
    uint256 public totalSupply;
     
    bool public lockAll = false;
     
    address public creator;
     
    address public owner;
     
    address internal newOwner = 0x0;

     
    mapping (address => uint256) public balanceOf;
     
    mapping (address => mapping (address => uint256)) public allowance;
     
    mapping (address => bool) public frozens;

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
     
    event TransferExtra(address indexed _from, address indexed _to, uint256 _value, bytes _extraData);
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
     
    event Burn(address indexed _from, uint256 _value);
     
    event Offer(uint256 _supplyTM);
     
    event OwnerChanged(address _oldOwner, address _newOwner);
     
    event FreezeAddress(address indexed _target, bool _frozen);

     
    constructor(uint256 initialSupplyHM, string tokenName, string tokenSymbol, uint8 tokenDecimals) public {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
        totalSupply = initialSupplyHM * 10000 * 10000 * 10 ** uint256(decimals);
        
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        creator = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner, "非法合约执行者");
        _;
    }
	
     
    function offer(uint256 _supplyTM) onlyOwner public returns (bool success){
         
        require(_supplyTM > 0, "无效数量");
		uint256 tm = _supplyTM * 1000 * 10000 * 10 ** uint256(decimals);
        totalSupply += tm;
        balanceOf[msg.sender] += tm;
        emit Offer(_supplyTM);
        return true;
    }

     
    function transferOwnership(address _newOwner) onlyOwner public returns (bool success){
        require(owner != _newOwner, "无效合约新所有者");
        newOwner = _newOwner;
        return true;
    }
    
     
    function acceptOwnership() public returns (bool success){
        require(msg.sender == newOwner && newOwner != 0x0, "无效合约新所有者");
        address oldOwner = owner;
        owner = newOwner;
        newOwner = 0x0;
        emit OwnerChanged(oldOwner, owner);
        return true;
    }

     
    function setLockAll(bool _lockAll) onlyOwner public returns (bool success){
        lockAll = _lockAll;
        return true;
    }

     
    function setFreezeAddress(address _target, bool _freeze) onlyOwner public returns (bool success){
        frozens[_target] = _freeze;
        emit FreezeAddress(_target, _freeze);
        return true;
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal {
         
        require(!lockAll, "合约处于锁定状态");
         
        require(_to != 0x0, "无效接收地址");
         
        require(_value > 0, "无效数量");
         
        require(balanceOf[_from] >= _value, "持有方转移数量不足");
         
        require(!frozens[_from], "持有方处于冻结状态"); 
         
         

         
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
         
		emit Transfer(_from, _to, _value);

         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
	
     
    function transferExtra(address _to, uint256 _value, bytes _extraData) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
		emit TransferExtra(msg.sender, _to, _value, _extraData);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
        require(_value <= allowance[_from][msg.sender], "授权额度不足");

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender); 
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function _burn(address _from, uint256 _value) internal {
         
        require(!lockAll, "合约处于锁定状态");
         
        require(balanceOf[_from] >= _value, "持有方余额不足");
         
        require(!frozens[_from], "持有方处于冻结状态"); 

         
        balanceOf[_from] -= _value;
         
        totalSupply -= _value;

        emit Burn(_from, _value);
    }

     
    function burn(uint256 _value) public returns (bool success) {
         
        require(_value > 0, "无效数量");

        _burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
         
        require(_value <= allowance[_from][msg.sender], "授权额度不足");
         
        require(_value > 0, "无效数量");
      
        allowance[_from][msg.sender] -= _value;

        _burn(_from, _value);
        return true;
    }

    function() payable public{
    }
}