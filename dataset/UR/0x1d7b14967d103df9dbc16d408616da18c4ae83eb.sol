 

pragma solidity ^0.4.23;

contract Owned {

    event OwnerChanged(address indexed from, address indexed to);

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function _transferOwnership(address _from, address _to) internal {
        owner = _to;
        emit OwnerChanged(_from, _to);
    }

    function transferOwnership(address newOwner) onlyOwner public {
        _transferOwnership(owner, newOwner);
    }
}

contract Whitelisted is Owned {

    event WhitelistModified(address indexed who, bool inWhitelist);

    mapping(address => bool) public whitelist;

    constructor() public {
        whitelist[msg.sender] = true;
    }

    function addToWhitelist(address who) public onlyOwner {
        whitelist[who] = true;
        emit WhitelistModified(who, true);
    }
    
    function removeFromWhitelist(address who) public onlyOwner {
        whitelist[who] = false;
        emit WhitelistModified(who, false);
    }

    modifier whitelisted {
        require(whitelist[msg.sender] == true);
        _;
    }

}

contract TokenERC20 {
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);

     
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value >= balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }

}

contract Ellobitz is TokenERC20, Owned, Whitelisted {

    uint256 public mineCount;
    uint256 public minMineSize;
    uint256 public maxMineSize;
    uint256 public chipSize;
    uint256 public firstChipBonus;
    uint public chipSpeed;

    uint256 internal activeMine;
    uint256 internal mineSize;
    bool internal firstChip;
    
    mapping(address => uint) public lastChipTime;

    event MineFound(address indexed chipper, uint256 activeMine);
    event MineChipped(address indexed chipper, uint256 indexed activeMine, uint256 amount);
    event MineExausted(address indexed chipper, uint256 activeMine);

    modifier validMineParameters (
        uint256 _mineCount,
        uint256 _minMineSize,
        uint256 _maxMineSize,
        uint256 _chipSize,
        uint256 _firstChipBonus,
        uint _chipSpeed
    ) {
        require(_minMineSize <= _maxMineSize, "Smallest mine size smaller than largest mine size");
        require(_chipSize + _firstChipBonus <= _minMineSize, "First chip would exhaust mine");
        _;
    }

    constructor(
        string tokenName,
        string tokenSymbol,
        uint256 _mineCount,
        uint256 _minMineSize,
        uint256 _maxMineSize,
        uint256 _chipSize,
        uint256 _firstChipBonus,
        uint _chipSpeed
    ) TokenERC20(0, tokenName, tokenSymbol) validMineParameters(
        _mineCount,
        _minMineSize,
        _maxMineSize,
        _chipSize,
        _firstChipBonus,
        _chipSpeed
    ) public {
        
         
        mineCount = _mineCount;
        minMineSize = _minMineSize;
        maxMineSize = _maxMineSize;
        chipSize = _chipSize;
        firstChipBonus = _firstChipBonus;
        chipSpeed = _chipSpeed;

         
        activeMine = 0;
        mineSize = minMineSize;
        firstChip = true;
    }

    function _resetMine() internal {
        activeMine = random() % mineCount;
        mineSize = random() % (maxMineSize - minMineSize + 1) + minMineSize;
        firstChip = true;
    }

    function chip(uint256 mineNumber) public whitelisted {
        
        require(mineNumber == activeMine, "Chipped wrong mine");
        require(now >= lastChipTime[msg.sender] + chipSpeed, "Chipped too fast");
        
        uint256 thisChipNoCap = firstChip ? firstChipBonus + chipSize : chipSize;
        uint256 thisChip = thisChipNoCap > mineSize ? mineSize : thisChipNoCap;

        if (firstChip) {
            emit MineFound(msg.sender, activeMine);
        }

        mineSize -= thisChip;
        mintToken(msg.sender, thisChip);
        lastChipTime[msg.sender] = now;
        firstChip = false;
        emit MineChipped(msg.sender, activeMine, thisChip);

        if (mineSize <= 0) {
            emit MineExausted(msg.sender, activeMine);
            _resetMine();
        }
    }

    function setParameters(
        uint256 _mineCount,
        uint256 _minMineSize,
        uint256 _maxMineSize,
        uint256 _chipSize,
        uint256 _firstChipBonus,
        uint _chipSpeed
    ) onlyOwner validMineParameters(
        _mineCount,
        _minMineSize,
        _maxMineSize,
        _chipSize,
        _firstChipBonus,
        _chipSpeed
    ) public {
        mineCount = _mineCount;
        minMineSize = _minMineSize;
        maxMineSize = _maxMineSize;
        chipSize = _chipSize;
        firstChipBonus = _firstChipBonus;
        chipSpeed = _chipSpeed;
    }

    function mintToken(address target, uint256 mintedAmount) internal {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(this, target, mintedAmount);
    }

     
    function random() internal view returns (uint256) {
        return uint256(keccak256(
            abi.encodePacked(block.timestamp, block.difficulty)
        ));
    }

}