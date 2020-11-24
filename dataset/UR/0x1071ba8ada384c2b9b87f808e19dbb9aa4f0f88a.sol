 

pragma solidity ^0.4.18;

     
    library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
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


    contract Owned {

         
         
        modifier onlyOwner() {
            require(msg.sender == owner);
            _;
        }

        address public owner;
         
        function Owned() public {
            owner = msg.sender;
        }

        address public newOwner;

         
         
         
        function changeOwner(address _newOwner) onlyOwner public {
            newOwner = _newOwner;
        }


        function acceptOwnership() public {
            if (msg.sender == newOwner) {
                owner = newOwner;
            }
        }
    }


    contract ERC20Protocol {
         
         
        uint public totalSupply;

         
         
        function balanceOf(address _owner) constant public returns (uint balance);

         
         
         
         
        function transfer(address _to, uint _value) public returns (bool success);

         
         
         
         
         
        function transferFrom(address _from, address _to, uint _value) public returns (bool success);

         
         
         
         
        function approve(address _spender, uint _value) public returns (bool success);

         
         
         
        function allowance(address _owner, address _spender) constant public returns (uint remaining);

        event Transfer(address indexed _from, address indexed _to, uint _value);
        event Approval(address indexed _owner, address indexed _spender, uint _value);
    }

    contract StandardToken is ERC20Protocol {
        using SafeMath for uint;

         
        modifier onlyPayloadSize(uint size) {
            require(msg.data.length >= size + 4);
            _;
        }

        function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) public returns (bool success) {
             
             
             
             
            if (balances[msg.sender] >= _value) {
                balances[msg.sender] -= _value;
                balances[_to] += _value;
                Transfer(msg.sender, _to, _value);
                return true;
            } else { return false; }
        }

        function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) public returns (bool success) {
             
             
            if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
                balances[_to] += _value;
                balances[_from] -= _value;
                allowed[_from][msg.sender] -= _value;
                Transfer(_from, _to, _value);
                return true;
            } else { return false; }
        }

        function balanceOf(address _owner) constant public returns (uint balance) {
            return balances[_owner];
        }

        function approve(address _spender, uint _value) onlyPayloadSize(2 * 32) public returns (bool success) {
             
             
             
             
            assert((_value == 0) || (allowed[msg.sender][_spender] == 0));

            allowed[msg.sender][_spender] = _value;
            Approval(msg.sender, _spender, _value);
            return true;
        }

        function allowance(address _owner, address _spender) constant public returns (uint remaining) {
        return allowed[_owner][_spender];
        }

        mapping (address => uint) balances;
        mapping (address => mapping (address => uint)) allowed;
    }

    contract SharesChainToken is StandardToken {
         
        string public constant name = "SharesChainToken";
        string public constant symbol = "SCTK";
        uint public constant decimals = 18;

         
        uint public constant MAX_TOTAL_TOKEN_AMOUNT = 20000000000 ether;

         
         
        address public minter;

         

        modifier onlyMinter {
            assert(msg.sender == minter);
            _;
        }

        modifier maxTokenAmountNotReached (uint amount){
            assert(totalSupply.add(amount) <= MAX_TOTAL_TOKEN_AMOUNT);
            _;
        }

         
        function SharesChainToken(address _minter) public {
            minter = _minter;
        }


         
        function mintToken(address recipient, uint _amount)
            public
            onlyMinter
            maxTokenAmountNotReached(_amount)
            returns (bool)
        {
            totalSupply = totalSupply.add(_amount);
            balances[recipient] = balances[recipient].add(_amount);
            return true;
        }
    }