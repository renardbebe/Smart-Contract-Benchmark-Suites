 

pragma solidity ^0.4.22;

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
        newOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(address(0) != _newOwner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, msg.sender);
        owner = msg.sender;
        newOwner = address(0);
    }
}
 

 
contract SafeMath {
     
    function SafeMath() public {
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 

contract TokenERC20 is SafeMath {
     
    string public name;
    string public symbol;
    
     
    uint8 public decimals = 18;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event ReceiveApproval(address _from, uint256 _value, address _token);

     
    event Burn(address indexed from, uint256 value);

     
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

     
    function TokenERC20() public {
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(safeAdd(balanceOf[_to],_value) > balanceOf[_to]);
         
        uint previousBalances = safeAdd(balanceOf[_from],balanceOf[_to]);
         
        balanceOf[_from] = safeSub(balanceOf[_from],_value);
         
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(32 * 3) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender],_value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) onlyPayloadSize(32 * 2) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit ReceiveApproval(msg.sender, _value, this);
        return true;
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender],_value);   
        totalSupply = safeSub(totalSupply,_value);                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) onlyPayloadSize(32 * 2) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] = safeSub(balanceOf[_from],_value);                          
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender],_value);              
        totalSupply = safeSub(totalSupply,_value);                               
        emit Burn(_from, _value);
        return true;
    }
}

 


contract OVC is Ownable, TokenERC20 {

    uint256 public ovcPerEther = 0;
    uint256 public minOVC;
    uint256 public constant ICO_START_TIME = 1526891400;  
    uint256 public constant ICO_END_TIME = 1532131199;  

    uint256 public totalOVCSold = 0;
    
    OVCLockAllocation public lockedAllocation;
    mapping (address => bool) public frozenAccount;
  
     
    event FrozenFunds(address target, bool frozen);
    event ChangeOvcEtherConversion(address owner, uint256 amount);
     
    function OVC() public {

        totalSupply = safeMul(83875000,(10 ** uint256(decimals) ));   
        name = "OVCODE";   
        symbol = "OVC";    
        
         
        balanceOf[msg.sender] = safeMul(30000000,(10 ** uint256(decimals))); 

         
         
        address icoAccount1 = 0xe5aB5D1Da8817bFB4b0Af44eFDcCC850a47E477a;
        balanceOf[icoAccount1] = safeMul(11000000,(10 ** uint256(decimals))); 

         
         
        address icoAccount2 = 0xfD382a7478ce3ddCd6a03F6c1848F31659753388;
        balanceOf[icoAccount2] = safeMul(10500000,(10 ** uint256(decimals))); 

         
        address bonusAccount = 0xAde1Cf49c41919658132FF003C409fBcb2909472;
        balanceOf[bonusAccount] = safeMul(1075000,(10 ** uint256(decimals)));
        
         
        address bountyAccount = 0xb690acb524BFBD968A91D614654aEEC5041597E0;
        balanceOf[bountyAccount] = safeMul(2450000,(10 ** uint256(decimals)));

         
        address investor1 = 0x17dC8dD84bD8DbAC168209360EDc1E8539D965DA;
        balanceOf[investor1] = safeMul(14850000,(10 ** uint256(decimals)));
        address investor2 = 0x5B2213eeFc9b7939D863085f7F2D9D1f3a771D5f;
        balanceOf[investor2] = safeMul(4000000,(10 ** uint256(decimals)));
        
         
        uint256 totalAllocation = safeMul(10000000,(10 ** uint256(decimals)));
        
         
        address firstAllocatedWallet = 0xD0427222388145a1A14F5FC4a376e8412C39c6a4;
        address secondAllocatedWallet = 0xe141c480274376A4eB499ACEeD84c47b5FDF4B39;
        address thirdAllocatedWallet = 0xD46811aBe15a53dd76b309E3e1f8f9C4550D3918;
        lockedAllocation = new OVCLockAllocation(totalAllocation,firstAllocatedWallet,secondAllocatedWallet,thirdAllocatedWallet);
         
        balanceOf[lockedAllocation] = totalAllocation;

         
        minOVC = safeMul(10,(10 ** uint256(decimals)));
    }
    
     
    function () public payable {
        buyTokens();
    }
    
     
    function changeOVCPerEther(uint256 amount) onlyPayloadSize(1 * 32) onlyOwner public {
        require(amount >= 0);
        ovcPerEther = amount;
        emit ChangeOvcEtherConversion(msg.sender, amount);
    }

     
    function transferUnsoldToken() onlyOwner public {
        require(now > ICO_END_TIME );
        require (balanceOf[this] > 0); 
        uint256 unsoldToken = balanceOf[this]; 
        _transfer(this, msg.sender, unsoldToken);
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (safeAdd(balanceOf[_to],_value) > balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] = safeSub(balanceOf[_from],_value); 
        balanceOf[_to] = safeAdd(balanceOf[_to],_value); 
        emit Transfer(_from, _to, _value);
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyPayloadSize(32 * 2) onlyOwner public {
        balanceOf[target] = safeAdd(balanceOf[target],mintedAmount);
        totalSupply = safeAdd(totalSupply,mintedAmount);
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
}

 


contract OVCLockAllocation is SafeMath {

    uint256 public totalLockAllocated;
    OVC public ovc;
     
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    struct Allocations {
        uint256 allocated;
        uint256 unlockedAt;
        bool released;
    }

    mapping (address => Allocations) public allocations;

     
     
     
     
     
     
    function OVCLockAllocation(uint256 totalAllocated, address firstAllocatedWallet, address secondAllocatedWallet, address thirdAllocatedWallet) public {
        ovc = OVC(msg.sender);
        totalLockAllocated = totalAllocated;
        Allocations memory allocation;

         
         
        allocation.allocated = safeDiv(safeMul(totalLockAllocated, 33),100);
        allocation.unlockedAt = safeAdd(now,(safeMul(12,30 days)));
        allocation.released = false;
        allocations[firstAllocatedWallet] = allocation;
        

         
         
        allocation.allocated = safeDiv(safeMul(totalLockAllocated, 33),100);
        allocation.unlockedAt = safeAdd(now,(safeMul(24,30 days)));
        allocation.released = false;
        allocations[secondAllocatedWallet] = allocation;

         
         
        allocation.allocated = safeDiv(safeMul(totalLockAllocated, 34),100);
        allocation.unlockedAt = safeAdd(now,(safeMul(36,30 days))); 
        allocation.released = false;
        allocations[thirdAllocatedWallet] = allocation;
    }
    
         
    function releaseTokens() public {
        Allocations memory allocation;
        allocation = allocations[msg.sender];
        require(allocation.released == false);
        require(allocation.allocated > 0);
        require(allocation.unlockedAt > 0);
        require(now >= allocation.unlockedAt);
            
        uint256 allocated = allocation.allocated;
        ovc.transfer(msg.sender, allocated);

        allocation.allocated = 0;
        allocation.unlockedAt = 0;
        allocation.released = true;
        allocations[msg.sender] = allocation;
    }
} 

 