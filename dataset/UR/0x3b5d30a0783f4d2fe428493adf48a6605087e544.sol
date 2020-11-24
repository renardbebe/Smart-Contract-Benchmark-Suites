 

pragma solidity ^0.4.20;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract XOXOEXToken is ERC20 {

    using SafeMath for uint256;
    address owner = msg.sender;

    bool public online = false;
    uint256 public onlinetime = now;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    mapping (address => bool) public frozenAccount;

    mapping (address => uint256) onlinelocknum;
    mapping (address => uint256) onlineexitnum;
    mapping (address => uint256) onlinelockexitmonth;
    mapping (address => uint256) onlinelockexittimes;
    mapping (address => uint256) onlinelockbrunnum;

    mapping (address => uint256) locktime;
    mapping (address => uint256) locknum;
    mapping (address => uint256) lockmonth;
    mapping (address => uint256) lockexittimes;
    mapping (address => uint256) lockburnnum;


    string public constant name = "XOXOEXToken";
    string public constant symbol = "XO";
    uint public constant decimals = 3;
    uint256 _Rate = 10 ** decimals;
    uint256 public totalSupply = 2000000000 * _Rate;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event FrozenFunds(address target, bool frozen);
    event Burn(address target,uint256 _value);
    event Online();



    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

     function XOXOEXToken() public {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

     function nowInSeconds() public view returns (uint256){
        return now;
    }

     
     function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {

        require( frozenAccount[_to] == false && frozenAccount[msg.sender] == false);

        require(_to != address(0));
        require(_amount <= (balances[msg.sender].sub(lockOf(msg.sender))));

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        Transfer(msg.sender, _to, _amount);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

        require( frozenAccount[_to] == false && frozenAccount[ _from] == false);

        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= balances[_from].sub(lockOf(msg.sender)));
        require(_amount <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }

    function balanceOf(address _owner) constant public returns (uint256) {
	    return balances[_owner];
    }

  

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0) && newOwner != owner) {
             owner = newOwner;
        }
    }

    function freeze(address target, bool B) onlyOwner public {
        frozenAccount[target] = B;
        FrozenFunds(target, B);
    }

  
  

    function locktransfer(address _to, uint256 _lockmonth, uint256 _month, uint256 _point) onlyOwner onlyPayloadSize(2 * 32) public returns (bool success) {
        require( frozenAccount[_to] == false);
        require( _point>= 0 && _point<= 10000);
        uint256 amount;
        amount = (totalSupply.div(10000)).mul( _point);

        require(_to != address(0));

        locked(_to ,_lockmonth ,_month, amount);

        Transfer(msg.sender, _to, amount);
        return true;
    }
  
    function onlinelocktransfer(address _to, uint256 _exitmonth, uint256 _exittime,uint256 _point,uint256 _onlineexitpoint) onlyOwner onlyPayloadSize(2 * 32) public returns (bool success) {
        require( frozenAccount[_to] == false);
        require( _point>= 0 && _point<= 10000);
        require( _onlineexitpoint>= 0 && _onlineexitpoint<= 10000);
        uint256 amount;
        amount = (totalSupply.div(10000)).mul( _point);
        uint256 exitamount;
        exitamount = (amount.div(10000)).mul( _onlineexitpoint);

        require(_to != address(0));

        onlinelocked(_to, _exitmonth,_exittime, amount,exitamount);

        Transfer(msg.sender, _to, amount);
        return true;
    }
 
    function burn(address _owner,uint256 _amount) onlyOwner public {
        uint256 lockednum = lockNum(_owner);
        uint256 onlinelockednum = onlinelockNum(_owner);
        require( _amount > 0);
        require( lockednum > 0 || onlinelockednum > 0);

        if( _amount <= lockednum.add(onlinelockednum)){
            if(_amount<=lockednum){
                lockburnnum[_owner] = lockburnnum[_owner].add(_amount);
            }else{
                lockburnnum[_owner] = lockburnnum[_owner].add(lockednum);
                onlinelockbrunnum[_owner] = onlinelockbrunnum[_owner].add(_amount.sub(lockednum));
            }
            balances[_owner] = balances[_owner].sub(_amount);
            balances[msg.sender] = balances[msg.sender].add(_amount);
            Burn( _owner,_amount);
        }else{
            lockburnnum[_owner] = lockburnnum[_owner].add(lockednum);
            onlinelockbrunnum[_owner] = onlinelockbrunnum[_owner].add(onlinelockednum);

            balances[_owner] = balances[_owner].sub(lockednum.add(onlinelockednum));
            balances[msg.sender] = balances[msg.sender].add(lockednum.add(onlinelockednum));
            Burn( _owner,lockednum.add(onlinelockednum));

        }
    }

 
    function lockOf(address _owner) constant public returns (uint256) {
	    return lockNum(_owner).add(onlinelockNum(_owner));
    }

    function onlineflag() onlyOwner public {
        require( online == false);
        online = true;
        onlinetime = now;
        Online();
    }

    function lockNum(address _owner) private returns (uint256) {
        uint lockednum = 0;
        uint256 nowtime = now;
        uint256 exitnum = lockburnnum[_owner];

        if(nowtime < locktime[_owner] + (lockmonth[_owner] + 1)*30* 1 days){
            lockednum = lockednum.add(locknum[_owner]);
        }
        else{
            if(nowtime < locktime[_owner] + (lockmonth[_owner] + lockexittimes[_owner])*30* 1 days){
				uint locknow = (nowtime - locktime[_owner] - lockmonth[_owner]*30* 1 days).div(30 * 1 days);
                lockednum = lockednum.add (((lockexittimes[_owner] - locknow).mul(locknum[_owner])).div(lockexittimes[_owner]));
            }
        }
        if(lockednum > exitnum){
            lockednum = lockednum.sub(exitnum);
        }else{
            lockednum = 0;
        }
        return lockednum;
    }

    function onlinelockNum(address _owner) private returns (uint256) {
        uint lockednum = 0;
        uint256 nowtime = now;
        uint256 exitnum = onlinelockbrunnum[_owner];
        if(online){
            if(onlinelockexitmonth[_owner] > 0 &&  onlinelockexittimes[_owner] > 0 ){
                if(nowtime < onlinetime + onlinelockexitmonth[_owner]* 30* 1 days){
                    lockednum =lockednum.add(onlinelocknum[_owner]).sub(onlineexitnum[_owner]) ;
                }
                else{
                    if(nowtime < onlinetime + onlinelockexitmonth[_owner] * onlinelockexittimes[_owner] * 30* 1 days){
				        uint onlinelocknow = (now - onlinetime).div(onlinelockexitmonth[_owner] * 30 * 1 days);
				        uint256 num = (onlinelockexittimes[_owner].sub(onlinelocknow)).mul(onlinelocknum[_owner].sub(onlineexitnum[_owner])).div(onlinelockexittimes[_owner]);
                        lockednum =lockednum.add(num);
                    }
                }
            }
        }else{
            lockednum = lockednum.add(onlinelocknum[_owner].sub(onlinelockbrunnum[_owner])) ;
        }
        if(lockednum > exitnum){
            lockednum = lockednum.sub(exitnum);
        }else{
            lockednum = 0;
        }
	    return lockednum;
    }


    function locked(address _to, uint256 _lockmonth, uint256 _month, uint256 _amount) private {
        uint256 lockednum = lockNum(_to);
        if(lockednum< _amount){
            require(_amount.sub(lockednum) <= (balances[msg.sender].sub(lockOf(msg.sender))));
            locktime[_to] = now;
            locknum[_to] = _amount;
            lockmonth[_to] = _lockmonth;
            lockexittimes[_to]= _month;
            lockburnnum[_to] = 0;
            balances[msg.sender] = balances[msg.sender].sub(_amount.sub(lockednum));
            balances[_to] = balances[_to].add(_amount.sub(lockednum));
        }else{
            locktime[_to] = now;
            locknum[_to] = _amount;
            lockmonth[_to] = _lockmonth;
            lockexittimes[_to]= _month;
            lockburnnum[_to] = 0;
            balances[msg.sender] = balances[msg.sender].add((lockednum.sub(_amount)));
            balances[_to] = balances[_to].sub(lockednum.sub(_amount));
        }

    }

    function onlinelocked(address _to, uint256 _exitmonth, uint256 _exittime,  uint256 _amount,  uint256 _exitamount) private {

        uint256 lockednum = onlinelockNum(_to);
        if(lockednum< _amount){
            require(_amount.sub(lockednum) <= (balances[msg.sender].sub(lockOf(msg.sender))));
            onlinelocknum[_to] = _amount;
            onlineexitnum[_to] = _exitamount;
            onlinelockexitmonth[_to] = _exitmonth;
            onlinelockexittimes[_to]= _exittime;
            onlinelockbrunnum[_to] =0;

            balances[msg.sender] = balances[msg.sender].sub(_amount.sub(lockednum));
            balances[_to] = balances[_to].add(_amount.sub(lockednum));
        }else{
            onlinelocknum[_to] = _amount;
            onlinelockexitmonth[_to] = _exitmonth;
            onlinelockexittimes[_to]= _exittime;
            onlineexitnum[_to] = _exitamount;
            onlinelockbrunnum[_to] =0;

            balances[msg.sender] = balances[msg.sender].add((lockednum.sub(_amount)));
            balances[_to] = balances[_to].sub(lockednum.sub(_amount));
        }
    }
}