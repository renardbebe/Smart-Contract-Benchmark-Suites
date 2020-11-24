 

pragma solidity ^0.4.2;

library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }
  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }
  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
 
}

 
contract TokenInterface {
         
        uint256 totalSupply;

         
        function balanceOf(address owner) constant returns(uint256 balance);
        function transfer(address to, uint256 value) returns(bool success);
        function transferFrom(address from, address to, uint256 value) returns(bool success);

         
        function approve(address spender, uint256 value) returns(bool success);

         
        function allowance(address owner, address spender) constant returns(uint256 remaining);

         
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is TokenInterface {
         
        mapping(address => uint256) balances;

         
        mapping(address => mapping(address => uint256)) allowed;

        address owner;
         
        address[] best_wals;
        uint[] best_count;

        function StandardToken() {
            for(uint8 i = 0; i < 10; i++) {
                best_wals.push(address(0));
                best_count.push(0);
            }
        }
        
         
        function transfer(address to, uint256 value) returns(bool success) {

                if (balances[msg.sender] >= value && value > 0) {
                         
                        balances[msg.sender] -= value;
                        balances[to] += value;

                        CheckBest(balances[to], to);

                         
                        Transfer(msg.sender, to, value);
                        return true;
                } else {

                        return false;
                }

        }

        function transferWithoutChangeBest(address to, uint256 value) returns(bool success) {

                if (balances[msg.sender] >= value && value > 0) {
                         
                        balances[msg.sender] -= value;
                        balances[to] += value;

                         
                        Transfer(msg.sender, to, value);
                        return true;
                } else {

                        return false;
                }

        }

         
        function transferFrom(address from, address to, uint256 value) returns(bool success) {

                if (balances[from] >= value &&
                        allowed[from][msg.sender] >= value &&
                        value > 0) {


                         
                        balances[from] -= value;
                        balances[to] += value;

                        CheckBest(balances[to], to);

                         
                         
                        allowed[from][msg.sender] -= value;

                         
                        Transfer(from, to, value);
                        return true;
                } else {

                        return false;
                }
        }

        function CheckBest(uint _tokens, address _address) {
             
            for(uint8 i = 0; i < 10; i++) {
                            if(best_count[i] < _tokens) {
                                for(uint8 j = 9; j > i; j--) {
                                    best_count[j] = best_count[j-1];
                                    best_wals[j] = best_wals[j-1];
                                }

                                best_count[i] = _tokens;
                                best_wals[i] = _address;
                                break;
                            }
                        }
        }

         
        function balanceOf(address owner) constant returns(uint256 balance) {
                return balances[owner];
        }

         
        function approve(address spender, uint256 value) returns(bool success) {

                 
                 
                allowed[msg.sender][spender] = value;

                 
                Approval(msg.sender, spender, value);

                return true;
        }

         
        function allowance(address owner, address spender) constant returns(uint256 remaining) {
                return allowed[owner][spender];
        }

}

contract LeviusDAO is StandardToken {

    string public constant symbol = "LeviusDAO";
    string public constant name = "LeviusDAO";

    uint8 public constant decimals = 8;
    uint DECIMAL_ZEROS = 10**8;

    modifier onlyOwner { assert(msg.sender == owner); _; }

    event BestCountTokens(uint _amount);
    event BestWallet(address _address);

     
    function LeviusDAO() {
        totalSupply = 5000000000 * DECIMAL_ZEROS;
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    function GetBestTokenCount(uint8 _num) returns (uint) {
        assert(_num < 10);
        BestCountTokens(best_count[_num]);
        return best_count[_num];
    }

    function GetBestWalletAddress(uint8 _num) onlyOwner returns (address) {
        assert(_num < 10);
        BestWallet(best_wals[_num]);
        return best_wals[_num];
    }
}