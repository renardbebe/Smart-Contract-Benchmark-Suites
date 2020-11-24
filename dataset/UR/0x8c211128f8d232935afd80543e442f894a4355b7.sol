 

pragma solidity ^0.4.24;

 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 
contract TokenController {
     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

     
     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount_old, uint _amount_new) public returns(bool);
}

 
 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

 
 
 
 
contract SNcoin_Token is ERC20Interface, Owned {
    string public constant symbol = "SNcoin";
    string public constant name = "scientificcoin";
    uint8 public constant decimals = 18;
    uint private constant _totalSupply = 100000000 * 10**uint(decimals);

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    struct LimitedBalance {
        uint8 limitType;
        uint initial;
    }
    mapping(address => LimitedBalance) limited_balances;
    uint8 public constant limitDefaultType = 0;
    uint8 public constant limitTeamType = 1;
    uint8 public constant limitBranchType = 2;
    uint8 private constant limitTeamIdx = 0;
    uint8 private constant limitBranchIdx = 1;
    uint8[limitBranchType] private limits;
    uint8 private constant limitTeamInitial = 90;
    uint8 private constant limitBranchInitial = 90;
    uint8 private constant limitTeamStep = 3;
    uint8 private constant limitBranchStep = 10;

    address public controller;
    
     
    bool public transfersEnabled;
     
     
     
    constructor() public {
        balances[owner] = _totalSupply;
        transfersEnabled = true;
        limits[limitTeamIdx] = limitTeamInitial;
        limits[limitBranchIdx] = limitBranchInitial;
        emit Transfer(address(0), owner, _totalSupply);
    }


     
     
    function setController(address _newController) public onlyOwner {
        controller = _newController;
    }
    
    function limitOfTeam() public constant returns (uint8 limit) {
        return 100 - limits[limitTeamIdx];
    }

    function limitOfBranch() public constant returns (uint8 limit) {
        return 100 - limits[limitBranchIdx];
    }

    function getLimitTypeOf(address tokenOwner) public constant returns (uint8 limitType) {
        return limited_balances[tokenOwner].limitType;
    }

    function getLimitedBalanceOf(address tokenOwner) public constant returns (uint balance) {
       if (limited_balances[tokenOwner].limitType > 0) {
           require(limited_balances[tokenOwner].limitType <= limitBranchType);
           uint minimumLimit = (limited_balances[tokenOwner].initial * limits[limited_balances[tokenOwner].limitType - 1])/100;
           require(balances[tokenOwner] >= minimumLimit);
           return balances[tokenOwner] - minimumLimit;
       }
       return balanceOf(tokenOwner);
    }

    function incrementLimitTeam() public onlyOwner returns (bool success) {
        require(transfersEnabled);

        uint8 previousLimit = limits[limitTeamIdx];
        if ( previousLimit - limitTeamStep >= 100) {
            limits[limitTeamIdx] = 0;
        } else {
            limits[limitTeamIdx] = previousLimit - limitTeamStep;
        }

        return true;
    }

    function incrementLimitBranch() public onlyOwner returns (bool success) {
        require(transfersEnabled);

        uint8 previousLimit = limits[limitBranchIdx];
        if ( previousLimit - limitBranchStep >= 100) {
            limits[limitBranchIdx] = 0;
        } else {
            limits[limitBranchIdx] = previousLimit - limitBranchStep;
        }

        return true;
    }

     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


     
     
     
     
     
     
     
     
    function approve(address _spender, uint _amount) public returns (bool success) {
        require(transfersEnabled);

         
        if (controller != 0) {
            require(TokenController(controller).onApprove(msg.sender, _spender, allowed[msg.sender][_spender], _amount));
        }

        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     
     
     
     
     
    function transfer(address _to, uint _amount) public returns (bool success) {
        require(transfersEnabled);
        doTransfer(msg.sender, _to, _amount);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
        require(transfersEnabled);

         
        require(allowed[_from][msg.sender] >= _amount);
        allowed[_from][msg.sender] -= _amount;
        doTransfer(_from, _to, _amount);
        return true;
    }


     
     
     
     
     
    function transferToTeam(address _to, uint _amount) public onlyOwner returns (bool success) {
        require(transfersEnabled);
        transferToLimited(msg.sender, _to, _amount, limitTeamType);

        return true;
    }


     
     
     
     
     
    function transferToBranch(address _to, uint _amount) public onlyOwner returns (bool success) {
        require(transfersEnabled);
        transferToLimited(msg.sender, _to, _amount, limitBranchType);

        return true;
    }


     
     
     
     
     
    function transferToLimited(address _from, address _to, uint _amount, uint8 _limitType) internal {
        require((_limitType >= limitTeamType) && (_limitType <= limitBranchType));
        require((limited_balances[_to].limitType == 0) || (limited_balances[_to].limitType == _limitType));

        doTransfer(_from, _to, _amount);

        uint previousLimitedBalanceInitial = limited_balances[_to].initial;
        require(previousLimitedBalanceInitial + _amount >= previousLimitedBalanceInitial);  
        limited_balances[_to].initial = previousLimitedBalanceInitial + _amount;
        limited_balances[_to].limitType = _limitType;
    }

     
     
     
     
     
     
     
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) public returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

     
     
     
    function () public payable {
        revert();
    }


     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount) internal {
           if (_amount == 0) {
               emit Transfer(_from, _to, _amount);     
               return;
           }

            
           require((_to != 0) && (_to != address(this)));

            
            
           uint previousBalanceFrom = balanceOf(_from);

           require(previousBalanceFrom >= _amount);

            
           if (controller != 0) {
               require(TokenController(controller).onTransfer(_from, _to, _amount));
           }

            
            
           balances[_from] = previousBalanceFrom - _amount;
           
           if (limited_balances[_from].limitType > 0) {
               require(limited_balances[_from].limitType <= limitBranchType);
               uint minimumLimit = (limited_balances[_from].initial * limits[limited_balances[_from].limitType - 1])/100;
               require(balances[_from] >= minimumLimit);
           }

            
            
           uint previousBalanceTo = balanceOf(_to);
           require(previousBalanceTo + _amount >= previousBalanceTo);  
           balances[_to] = previousBalanceTo + _amount;

            
           emit Transfer(_from, _to, _amount);
    }

     
     
    function enableTransfers(bool _transfersEnabled) public onlyOwner {
        transfersEnabled = _transfersEnabled;
    }

     
     
     
     
    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }

        ERC20Interface token = ERC20Interface(_token);
        uint balance = token.balanceOf(this);
        token.transfer(owner, balance);
        emit ClaimedTokens(_token, owner, balance);
    }
    
    event ClaimedTokens(address indexed _token, address indexed _owner, uint _amount);
}