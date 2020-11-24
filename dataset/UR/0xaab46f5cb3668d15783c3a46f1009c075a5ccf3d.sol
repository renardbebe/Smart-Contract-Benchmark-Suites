 

pragma solidity ^0.4.21;

 
library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
         
        uint c = a / b;
         
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}


 
contract ERC20Basic {
    uint public totalSupply;
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
}




 
contract BasicToken is ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) balances;

     
    modifier onlyPayloadSize(uint size) {
        if(msg.data.length < size + 4) {
            revert();
        }
        _;
    }

     
    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

}




 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint value);
}




 
contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint)) allowed;


     
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) returns (bool) {
        uint _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint _value) public returns (bool) {

         
         
         
         
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}


 

contract LimitedTransferToken is ERC20 {

     
    modifier canTransfer(address _sender, uint _value) {
        if (_value > transferableTokens(_sender, now, block.number)) revert();
        _;
    }

     
    function transfer(address _to, uint _value) public canTransfer(msg.sender, _value) returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value) public canTransfer(_from, _value) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
    function transferableTokens(address holder, uint  , uint  ) view public returns (uint256) {
        return balanceOf(holder);
    }
}


 
contract VestedToken is StandardToken, LimitedTransferToken {

    uint256 MAX_GRANTS_PER_ADDRESS = 20;

    struct TokenGrant {
        address granter;          
        uint256 value;              
        uint start;
        uint cliff;
        uint vesting;                 
        bool revokable;
        bool burnsOnRevoke;     
        bool timeOrNumber;
    }  

    mapping (address => TokenGrant[]) public grants;

    event NewTokenGrant(address indexed from, address indexed to, uint256 value, uint256 grantId);

     
    function grantVestedTokens(
        address _to,
        uint256 _value,
        uint _start,
        uint _cliff,
        uint _vesting,
        bool _revokable,
        bool _burnsOnRevoke,
        bool _timeOrNumber
    ) public returns (bool) {

         
        if (_cliff < _start || _vesting < _cliff) {
            revert();
        }

         
        if (tokenGrantsCount(_to) > MAX_GRANTS_PER_ADDRESS) revert();

        uint count = grants[_to].push(
            TokenGrant(
                _revokable ? msg.sender : 0,  
                _value,
                _start,
                _cliff,
                _vesting,
                _revokable,
                _burnsOnRevoke,
                _timeOrNumber
            )
        );

        transfer(_to, _value);

        emit NewTokenGrant(msg.sender, _to, _value, count - 1);
        return true;
    }

     
    function revokeTokenGrant(address _holder, uint _grantId) public returns (bool) {
        TokenGrant storage grant = grants[_holder][_grantId];

        if (!grant.revokable) {  
            revert();
        }

        if (grant.granter != msg.sender) {  
            revert();
        }

        address receiver = grant.burnsOnRevoke ? 0xdead : msg.sender;

        uint256 nonVested = nonVestedTokens(grant, now, block.number);

         
        delete grants[_holder][_grantId];
        grants[_holder][_grantId] = grants[_holder][grants[_holder].length.sub(1)];
        grants[_holder].length -= 1;

        balances[receiver] = balances[receiver].add(nonVested);
        balances[_holder] = balances[_holder].sub(nonVested);

        emit Transfer(_holder, receiver, nonVested);
        return true;
    }


     
    function transferableTokens(address holder, uint time, uint number) view public returns (uint256) {
        uint256 grantIndex = tokenGrantsCount(holder);

        if (grantIndex == 0) return balanceOf(holder);  

         
        uint256 nonVested = 0;
        for (uint256 i = 0; i < grantIndex; i++) {
            nonVested = SafeMath.add(nonVested, nonVestedTokens(grants[holder][i], time, number));
        }

         
        uint256 vestedTransferable = SafeMath.sub(balanceOf(holder), nonVested);

         
         
        return SafeMath.min256(vestedTransferable, super.transferableTokens(holder, time, number));
    }

     
    function tokenGrantsCount(address _holder) public view returns (uint index) {
        return grants[_holder].length;
    }

     
    function calculateVestedTokensTime(
        uint256 tokens,
        uint256 time,
        uint256 start,
        uint256 cliff,
        uint256 vesting) public pure returns (uint256) {
         
        if (time < cliff) return 0;
        if (time >= vesting) return tokens;

         
         
         

         
        uint256 vestedTokens = SafeMath.div(SafeMath.mul(tokens, SafeMath.sub(time, start)), SafeMath.sub(vesting, start));

        return vestedTokens;
    }

    function calculateVestedTokensNumber(
        uint256 tokens,
        uint256 number,
        uint256 start,
        uint256 cliff,
        uint256 vesting) public pure returns (uint256) {
         
        if (number < cliff) return 0;
        if (number >= vesting) return tokens;

         
         
         

         
        uint256 vestedTokens = SafeMath.div(SafeMath.mul(tokens, SafeMath.sub(number, start)), SafeMath.sub(vesting, start));

        return vestedTokens;
    }

    function calculateVestedTokens(
        bool timeOrNumber,
        uint256 tokens,
        uint256 time,
        uint256 number,
        uint256 start,
        uint256 cliff,
        uint256 vesting) public pure returns (uint256) {
        if (timeOrNumber) {
            return calculateVestedTokensTime(
                tokens,
                time,
                start,
                cliff,
                vesting
            );
        } else {
            return calculateVestedTokensNumber(
                tokens,
                number,
                start,
                cliff,
                vesting
            );
        }
    }

     
    function tokenGrant(address _holder, uint _grantId) public view 
        returns (address granter, uint256 value, uint256 vested, uint start, uint cliff, uint vesting, bool revokable, bool burnsOnRevoke, bool timeOrNumber) {
        TokenGrant storage grant = grants[_holder][_grantId];

        granter = grant.granter;
        value = grant.value;
        start = grant.start;
        cliff = grant.cliff;
        vesting = grant.vesting;
        revokable = grant.revokable;
        burnsOnRevoke = grant.burnsOnRevoke;
        timeOrNumber = grant.timeOrNumber;

        vested = vestedTokens(grant, now, block.number);
    }

     
    function vestedTokens(TokenGrant grant, uint time, uint number) private pure returns (uint256) {
        return calculateVestedTokens(
            grant.timeOrNumber,
            grant.value,
            uint256(time),
            uint256(number),
            uint256(grant.start),
            uint256(grant.cliff),
            uint256(grant.vesting)
        );
    }

     
    function nonVestedTokens(TokenGrant grant, uint time, uint number) private pure returns (uint256) {
        return grant.value.sub(vestedTokens(grant, time, number));
    }

     
    function lastTokenIsTransferableDate(address holder) view public returns (uint date) {
        date = now;
        uint256 grantIndex = grants[holder].length;
        for (uint256 i = 0; i < grantIndex; i++) {
            if (grants[holder][i].timeOrNumber) {
                date = SafeMath.max256(grants[holder][i].vesting, date);
            }
        }
    }
    function lastTokenIsTransferableNumber(address holder) view public returns (uint number) {
        number = block.number;
        uint256 grantIndex = grants[holder].length;
        for (uint256 i = 0; i < grantIndex; i++) {
            if (!grants[holder][i].timeOrNumber) {
                number = SafeMath.max256(grants[holder][i].vesting, number);
            }
        }
    }
}

 
 

 


contract GOCToken is VestedToken {
     
    string public name = "Global Optimal Chain";
    string public symbol = "GOC";
    uint public decimals = 18;
    uint public INITIAL_SUPPLY = 20 * 100000000 * 1 ether;
    uint public iTime;
    uint public iBlock;

     
    function GOCToken() public {
        totalSupply = INITIAL_SUPPLY;
        iTime = now;
        iBlock = block.number;

        address toAddress = msg.sender;
        balances[toAddress] = totalSupply;

        grantVestedTokens(toAddress, totalSupply.div(100).mul(30), iTime, iTime, iTime, false, false, true);

        grantVestedTokens(toAddress, totalSupply.div(100).mul(30), iTime, iTime + 365 days, iTime + 365 days, false, false, true);

        grantVestedTokens(toAddress, totalSupply.div(100).mul(20), iTime + 1095 days, iTime + 1095 days, iTime + 1245 days, false, false, true);
        
        uint startMine = uint(1054080) + block.number; 
        uint finishMine = uint(210240000) + block.number; 
        grantVestedTokens(toAddress, totalSupply.div(100).mul(20), startMine, startMine, finishMine, false, false, false);
    }

     
    function transfer(address _to, uint _value) public returns (bool) {
         
        if (_to == msg.sender) return false;
        return super.transfer(_to, _value);
    }

     
     
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function currentTransferableTokens(address holder) view public returns (uint256) {
        return transferableTokens(holder, now, block.number);
    }
}