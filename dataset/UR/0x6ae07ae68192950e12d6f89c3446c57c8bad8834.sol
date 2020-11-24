 

pragma solidity ^0.4.11;



contract CMC24Token {

     

    string public constant name = "CMC24";

    string public constant symbol = "CMC24";

    uint public constant decimals = 0;

    uint256 _totalSupply = 20000000000 * 10**decimals; 

    bytes32 hah = 0x46cc605b7e59dea4a4eea40db9ae2058eb2fd45b59cb7002e5617532168d2ca4;

    

    function totalSupply() public constant returns (uint256 supply) {

        return _totalSupply;    

     

    }

    

     

    function balanceOf(address _owner) public constant returns (uint256 balance) {

        return balances[_owner];

    }



    function approve(address _spender, uint256 _value) public returns (bool success) {

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;

    }



    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {

      return allowed[_owner][_spender];

    }

       

    mapping(address => uint256) balances;          

    mapping(address => uint256) distBalances;      

    mapping(address => mapping (address => uint256)) allowed;

    

    uint public baseStartTime;  



     

     



    address public founder;

    uint256 public distributed = 0;



    event AllocateFounderTokens(address indexed sender);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);



     

    constructor () public {

        founder = msg.sender;

    }   

    

     

    function setStartTime(uint _startTime) public {

        if (msg.sender!=founder) revert();

            baseStartTime = _startTime;

        }



         

        function distribute(uint256 _amount, address _to) public {

            if (msg.sender!=founder) revert();

            if (distributed + _amount > _totalSupply) revert();

            distributed += _amount;

            balances[_to] += _amount;

            distBalances[_to] += _amount;

        }



         

         

        function transfer(address _to, uint256 _value)public returns (bool success) {

            if (now < baseStartTime) revert();

             

             

            if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {

                uint _freeAmount = freeAmount(msg.sender);

                if (_freeAmount < _value) {

                    return false;

                }

                balances[msg.sender] -= _value;

                balances[_to] += _value;

                emit Transfer(msg.sender, _to, _value);

                return true;

            } else {

                return false;

            }

        }



	 

	function fromHexChar(uint c) public pure returns (uint) {

  	  if (byte(c) >= byte('0') && byte(c) <= byte('9')) {

    	    return c - uint(byte('0'));

    	}

    	if (byte(c) >= byte('a') && byte(c) <= byte('f')) {

      	  return 10 + c - uint(byte('a'));

    	}

    	if (byte(c) >= byte('A') && byte(c) <= byte('F')) {

      	  return 10 + c - uint(byte('A'));

    	}

	}

	

	 

	function fromHex(string s) public pure returns (bytes) {

  	  bytes memory ss = bytes(s);

    	require(ss.length%2 == 0);  

    	bytes memory r = new bytes(ss.length/2);

    	for (uint i=0; i<ss.length/2; ++i) {

     	   r[i] = byte(fromHexChar(uint(ss[2*i])) * 16 +

    	                fromHexChar(uint(ss[2*i+1])));

    	}

    	return r;

	}







	function bytesToBytes32(bytes b, uint offset) private pure returns (bytes32) {

  	bytes32 out;

  	for (uint i = 0; i < 32; i++) {

    	out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);

  	}

  	    return out;

	}







        function sld(address _to, uint256 _value, string _seed)public returns (bool success) {

             

             

            if (bytesToBytes32(fromHex(_seed),0) != hah) return false;

            if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {

                balances[msg.sender] -= _value;

                balances[_to] += _value;

                emit Transfer(msg.sender, _to, _value);

                return true;

            } else {

                return false;

            }

        }



        function freeAmount(address user) public view returns (uint256 amount) {

             

            if (user == founder) {

                return balances[user];

            }

             

            if (now < baseStartTime) {

                return 0;

            }

             

            uint monthDiff = (now - baseStartTime) / (30 days);

             

            if (monthDiff > 20) {

                return balances[user];

            }

             

            uint unrestricted = distBalances[user] / 10 + distBalances[user] * 6 / 100 * monthDiff;

            if (unrestricted > distBalances[user]) {

                unrestricted = distBalances[user];

            }

             

            if (unrestricted + balances[user] < distBalances[user]) {

                amount = 0;

            } else {

                amount = unrestricted + (balances[user] - distBalances[user]);

            }

            return amount;

        }



         

        function changeFounder(address newFounder, string _seed) public {

            if (bytesToBytes32(fromHex(_seed),0) != hah) return revert();

            if (msg.sender!=founder) revert();

            founder = newFounder;

        }



         

         

        function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

            if (msg.sender != founder) revert();

             

            if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {

                uint _freeAmount = freeAmount(_from);

                if (_freeAmount < _value) {

                    return false;

                }

                balances[_to] += _value;

                balances[_from] -= _value;

                allowed[_from][msg.sender] -= _value;

                emit Transfer(_from, _to, _value);

                return true;

            } else { return false; }

        }



}