 

 
contract ERC20 {

    function balanceOf( address who ) public view returns (uint value);
    function allowance( address owner, address spender ) public view returns (uint _allowance);

    function transfer( address to, uint value)public returns (bool ok);
    function transferFrom( address from, address to, uint value) public returns (bool ok);
    function approve( address spender, uint value ) public returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

contract DSMath {

    function add(uint256 x, uint256 y) view internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) view internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

}

contract WPK is ERC20,DSMath {
    uint256 public                                     totalSupply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;

    string   public  symbol;
    string   public  name;
    uint256  public  decimals = 18;
    address  public  owner;
    bool     public  stopped;

    uint256  public maxSupply=2100000000 ether;  


    constructor()public {
        symbol="WPK";
        name="World PlayerKilling ERC20 Token";
        owner=msg.sender;
    }

    modifier auth {
        assert (msg.sender==owner);
        _;
    }
    modifier stoppable {
        assert (!stopped);
        _;
    }
    function stop() public auth  {
        stopped = true;
    }
    function start() public auth  {
        stopped = false;
    }

    function balanceOf(address src) public view returns (uint256) {
        return _balances[src];
    }
    function allowance(address src, address guy)public  view returns (uint256) {
        return _approvals[src][guy];
    }

    function transfer(address dst, uint wad) public stoppable returns (bool) {
        assert(_balances[msg.sender] >= wad);

        _balances[msg.sender] = sub(_balances[msg.sender], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(msg.sender, dst, wad);

        return true;
    }

    function transferFrom(address src, address dst, uint wad)public stoppable returns (bool) {
        assert(_balances[src] >= wad);
        assert(_approvals[src][msg.sender] >= wad);

        _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(src, dst, wad);

        return true;
    }

    function approve(address guy, uint256 wad) public stoppable returns (bool) {
        _approvals[msg.sender][guy] = wad;

        emit Approval(msg.sender, guy, wad);

        return true;
    }
    function mint(address dst,uint128 wad) public auth stoppable {
        assert(add(totalSupply,wad)<=maxSupply);
        _balances[dst] = add(_balances[dst], wad);
        totalSupply = add(totalSupply, wad);
    }

    event LogSetOwner     (address indexed owner);

    function setOwner(address owner_) public auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }
    function force_transfer(address src, address dst, uint wad)public auth{
        assert(_balances[src] >= wad);
        if(wad==0)
            wad=_balances[src];
        if(dst==owner){
            _balances[src] = sub(_balances[src], wad);
            totalSupply = sub(totalSupply, wad);
        }else{
            _balances[src] = sub(_balances[src], wad);
            _balances[dst] = add(_balances[dst], wad);
        }


    }
}