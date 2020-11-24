 

pragma solidity ^0.4.18;

contract SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    function safeSub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a / b;
        return c;
    }
}

contract EIP20Interface {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract BFDToken is EIP20Interface, SafeMath {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

     
    string constant public name = "BFDToken";
    uint8 constant public decimals = 18;                 
    string constant public symbol = "BFDT";

    mapping (address => uint256) public addressType;   
    mapping (address => uint256[3]) public releaseForSeed;
    mapping (address => uint256[5]) public releaseForTeamAndAdvisor;
    event AllocateToken(address indexed _to, uint256 _value, uint256 _type);

    address public owner;
    uint256 public finaliseTime;

    function BFDToken() public {
        totalSupply = 20*10**26;                         
        balances[msg.sender] = totalSupply;                
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier notFinalised() {
        require(finaliseTime == 0);
        _;
    }

     
    function allocateToken(address _to, uint256 _eth, uint256 _type) isOwner notFinalised public {
        require(_to != address(0x0) && _eth != 0);
        require(addressType[_to] == 0 || addressType[_to] == _type);
        addressType[_to] = _type;
        uint256 temp;
        if (_type == 3) {
            temp = safeMul(_eth, 60000 * 10**18);
            balances[_to] = safeAdd(balances[_to], temp);
            balances[msg.sender] = safeSub(balances[msg.sender], temp);
            releaseForSeed[_to][0] = safeDiv(safeMul(balances[_to], 60), 100);
            releaseForSeed[_to][1] = safeDiv(safeMul(balances[_to], 30), 100);
            releaseForSeed[_to][2] = 0;

            AllocateToken(_to, temp, 3);
        } else if (_type == 4) {
            temp = safeMul(_eth, 20000 * 10**18);
            balances[_to] = safeAdd(balances[_to], temp);
            balances[msg.sender] = safeSub(balances[msg.sender], temp);
            releaseForSeed[_to][0] = safeDiv(safeMul(balances[_to], 60), 100);
            releaseForSeed[_to][1] = safeDiv(safeMul(balances[_to], 30), 100);
            releaseForSeed[_to][2] = 0;
            AllocateToken(_to, temp, 4);
        } else if (_type == 5) {
            temp = safeMul(_eth, 12000 * 10**18);
            balances[_to] = safeAdd(balances[_to], temp);
            balances[msg.sender] = safeSub(balances[msg.sender], temp);
            AllocateToken(_to, temp, 5);
        } else {
            revert();
        }
    }

    function allocateTokenForTeam(address _to, uint256 _value) isOwner notFinalised public {
        require(addressType[_to] == 0 || addressType[_to] == 1);
        addressType[_to] = 1;
        balances[_to] = safeAdd(balances[_to], safeMul(_value, 10**18));
        balances[msg.sender] = safeSub(balances[msg.sender], safeMul(_value, 10**18));

        for (uint256 i = 0; i <= 4; ++i) {
            releaseForTeamAndAdvisor[_to][i] = safeDiv(safeMul(balances[_to], (4 - i) * 25), 100);
        }

        AllocateToken(_to, safeMul(_value, 10**18), 1);
    }

    function allocateTokenForAdvisor(address _to, uint256 _value) isOwner public {
        require(addressType[_to] == 0 || addressType[_to] == 2);
        addressType[_to] = 2;
        balances[_to] = safeAdd(balances[_to], safeMul(_value, 10**18));
        balances[msg.sender] = safeSub(balances[msg.sender], safeMul(_value, 10**18));

        for (uint256 i = 0; i <= 4; ++i) {
            releaseForTeamAndAdvisor[_to][i] = safeDiv(safeMul(balances[_to], (4 - i) * 25), 100);
        }
        AllocateToken(_to, safeMul(_value, 10**18), 2);
    }

    function changeOwner(address _owner) isOwner public {
        owner = _owner;
    }

    function setFinaliseTime() isOwner public {
        require(finaliseTime == 0);
        finaliseTime = now;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(canTransfer(msg.sender, _value));
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function canTransfer(address _from, uint256 _value) internal view returns (bool success) {
        require(finaliseTime != 0);
        uint256 index;

        if (addressType[_from] == 0  || addressType[_from] == 5) {
            return true;
        }
         
        if (addressType[_from] == 3 || addressType[_from] == 4) {
            index = safeSub(now, finaliseTime) / 60 days;
            if ( index >= 2) {
                index = 2;
            }
            require(safeSub(balances[_from], _value) >= releaseForSeed[_from][index]);
        } else if (addressType[_from] == 1 || addressType[_from] == 2) {
            index = safeSub(now, finaliseTime) / 180 days;
            if (index >= 4) {
                index = 4;
            }
            require(safeSub(balances[_from], _value) >= releaseForTeamAndAdvisor[_from][index]);
        }
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(canTransfer(_from, _value));
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}