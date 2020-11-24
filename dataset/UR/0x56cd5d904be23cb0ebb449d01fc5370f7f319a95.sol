 

pragma solidity ^0.5.4;

 
 
 
 
 
 
 
 
 
 

 
 
 
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
        
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


 
 
 
 
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address payable token, bytes memory data) public;
}


 
 
 
contract Owned {
    address payable public _owner;
    address payable private _newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        _owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        _newOwner = newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == _newOwner);
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
        _newOwner = address(0);
    }
}


 
 
 
 
contract XYZZ is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public name;
    string public description;
    uint8 public decimals;    
    uint private _startDate;
    uint private _bonusEnds;
    uint private _endDate;
    
    uint256 private _internalCap;
    uint256 private _softCap;
    uint256 private _totalSupply;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowed;
    mapping(address => bool) _freezeState;


     
     
     
    constructor(
        address payable minter) public {
        
        name   = "VGNA Token";
        description = "Virtual Geospatial Networking Asset";
        symbol = "VGNA";
        decimals = 18;
        _internalCap = 25000000;
        _softCap     = 50000000;
        
        _bonusEnds = now + 3 days;
        _endDate = now + 1 weeks;
            
        _owner = minter;
        _balances[_owner] = _internalCap;  
        _totalSupply = _internalCap;
        emit Transfer(address(0), _owner, _internalCap);
    }

    modifier IcoSuccessful {
        require(now >= _endDate);
        require(_totalSupply >= _softCap);
        _;
    }


     
     
     
    function totalSupply() public view returns (uint) {
        return _totalSupply - _balances[address(0)];
    }


     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return _balances[tokenOwner];
    }
    
    function isFreezed(address tokenOwner) public view returns (bool freezed) {
        return _freezeState[tokenOwner];
    }


     
     
     
     
     
    function transfer(address to, uint256 tokens) public IcoSuccessful returns (bool success) {
        require(_freezeState[msg.sender] == false);
        
        _balances[msg.sender] = safeSub(_balances[msg.sender], tokens);
        _balances[to] = safeAdd(_balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    

     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public IcoSuccessful returns (bool success) {
        require( _freezeState[spender] == false);
        _allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public IcoSuccessful returns (bool success) {
        require( _freezeState[from] == false && _freezeState[to] == false);
        
        _balances[from] = safeSub(_balances[from], tokens);
        _allowed[from][msg.sender] = safeSub(_allowed[from][msg.sender], tokens);
        _balances[to] = safeAdd(_balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        require(_freezeState[spender] == false);
        return _allowed[tokenOwner][spender];
    }

     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes memory data) public IcoSuccessful returns (bool success) {
        require(_freezeState[spender] == false);
        _allowed[msg.sender][spender] = tokens;
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, _owner, data);
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

     
     
     
    function buy() public payable {
    
        require(msg.value >= 1 finney);
        require(now >= _startDate && now <= _endDate);

        uint256 weiValue = msg.value;
        uint256 tokens = 0;
        
        if (now <= _bonusEnds) {
            tokens = safeMul(weiValue, 2);
        } else {
            tokens = safeMul(weiValue, 1);
        }
        
        _freezeState[msg.sender] = true;
        _balances[msg.sender] = safeAdd(_balances[msg.sender], tokens);
        _totalSupply = safeAdd(_totalSupply, tokens);
        emit Transfer(address(0), msg.sender, tokens);
        _owner.transfer(msg.value);
    }
    
    function () payable external {
        buy();
    }

    function burn(uint256 tokens) public onlyOwner returns (bool success) {
        require(_balances[msg.sender] >= tokens);    
        address burner = msg.sender;
        _balances[burner] = safeSub(_balances[burner], tokens);
        _totalSupply = safeSub(_totalSupply, tokens);
        emit Transfer(burner, address(0), tokens);
        return true;
    }
    
    function burnFrom(address account, uint256 tokens) public onlyOwner returns (bool success) {
        require(_balances[account] >= tokens);    
        address burner = account;
        _balances[burner] = safeSub(_balances[burner], tokens);
        _totalSupply = safeSub(_totalSupply, tokens);
        emit Transfer(burner, address(0), tokens);
        return true;
    }
    
    function freeze(address account) public onlyOwner returns (bool success) {
        require(account != _owner && account != address(0));
        _freezeState[account] = true;
        return true;
    }
    
    function unfreeze(address account) public onlyOwner returns (bool success) {
        require(account != _owner && account != address(0));
        _freezeState[account] = false;
        return true;
    }
    
    function mint(uint256 tokens) public onlyOwner returns (bool success)
    {
        require(now >= _startDate && now <= _endDate);
        _balances[msg.sender] = safeAdd(_balances[msg.sender], tokens);
        _totalSupply = safeAdd(_totalSupply, tokens);
        emit Transfer(address(0), msg.sender, tokens);
        return true;
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(_owner, tokens);
    }
}