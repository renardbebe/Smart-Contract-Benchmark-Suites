 

pragma solidity ^0.4.23;

 
library SafeMath {
   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ptc {
    function balanceOf(address _owner) constant public returns (uint256);
}

contract Jade {
    using SafeMath for uint256;
     
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals = 3;
    uint256 public totalMember;

    uint256 private tickets = 50*(10**18);
    uint256 private max_level = 20;
    uint256 private ajust_time = 30*24*60*60;
    uint256 private min_interval = (24*60*60 - 30*60);
    uint256 private creation_time;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public levels;

    mapping (address => uint256) private last_mine_time;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

    address private ptc_addr = 0xeCa906474016f727D1C2Ec096046C03eAc4Aa085;
    Ptc ptc_ins = Ptc(ptc_addr);

    constructor(string _name, string _symbol) public{
        totalSupply = 0;
        totalMember = 0;
        creation_time = now;
        name = _name;
        symbol = _symbol;
    }

     
    modifier only_ptc_owner {
        require(ptc_ins.balanceOf(msg.sender) >= tickets);
        _;
    }

     
    function transfer(address _to, uint256 _value) public only_ptc_owner{
         
        require (balanceOf[msg.sender] >= _value);
        require (balanceOf[_to] + _value >= balanceOf[_to]);

         
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

         
        emit Transfer(msg.sender, _to, _value);
    }

    function ptc_balance(address addr) constant public returns(uint256){
        return ptc_ins.balanceOf(addr);
    }

    function rest_time() constant public only_ptc_owner returns(uint256) {
        if (now >= last_mine_time[msg.sender].add(min_interval))
            return 0;
        else
            return last_mine_time[msg.sender].add(min_interval).sub(now);
    }

    function catch_the_thief(address check_addr) public only_ptc_owner returns(bool){
        if (ptc_ins.balanceOf(check_addr) < tickets) {
            levels[msg.sender] = levels[msg.sender].add(levels[check_addr]);
            update_power();

            balanceOf[check_addr] = 0;
            levels[check_addr] = 0;
            return true;
        }
        return false;
    }

    function mine_jade() public only_ptc_owner returns(uint256) {
        if (last_mine_time[msg.sender] == 0) {
            last_mine_time[msg.sender] = now;
            update_power();

            balanceOf[msg.sender] = mine_jade_ex(levels[msg.sender]);
            totalSupply = totalSupply.add(mine_jade_ex(levels[msg.sender]));
            totalMember = totalMember.add(1);

            return mine_jade_ex(levels[msg.sender]);
        } else if (now >= last_mine_time[msg.sender].add(min_interval)) {
            last_mine_time[msg.sender] = now;
            update_power();

            balanceOf[msg.sender] = balanceOf[msg.sender].add(mine_jade_ex(levels[msg.sender]));
            totalSupply = totalSupply.add(mine_jade_ex(levels[msg.sender]));

            return mine_jade_ex(levels[msg.sender]);
        } else {
            return 0;
        }
    }

    function mine_jade_ex(uint256 power) private view returns(uint256) {
        uint256 cycle = now.sub(creation_time).div(ajust_time);
        require (cycle >= 0);
        require (power >= 0);
        require (power <= max_level);

        return ((100*power + 20*(power**2)).mul(95**cycle)).div(100**cycle);
    }

    function update_power() private {
        require (levels[msg.sender] >= 0);
        if (levels[msg.sender] < max_level)
            levels[msg.sender] = levels[msg.sender].add(1);
        else
            levels[msg.sender] = max_level;
    }
}