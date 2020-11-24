 

 
 

 
 
 
 
 
 
 
 
 
 
 
 

pragma solidity 0.5.12;

contract VatLike {
    function hope(address) external;
}

contract PotLike {
    function chi() external returns (uint256);
    function rho() external returns (uint256);
    function drip() external returns (uint256);
    function join(uint256) external;
    function exit(uint256) external;
}

contract JoinLike {
    function join(address, uint) external;
    function exit(address, uint) external;
}

contract GemLike {
    function transferFrom(address,address,uint) external returns (bool);
    function approve(address,uint) external returns (bool);
}

contract Chai {
     
    VatLike  public vat = VatLike(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    PotLike  public pot = PotLike(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    JoinLike public daiJoin = JoinLike(0x9759A6Ac90977b93B58547b4A71c78317f391A28);
    GemLike  public daiToken = GemLike(0x6B175474E89094C44Da98b954EedeAC495271d0F);

     
    string  public constant name     = "Chai";
    string  public constant symbol   = "CHAI";
    string  public constant version  = "1";
    uint8   public constant decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint)                      public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    mapping (address => uint)                      public nonces;

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);

     
    uint constant RAY = 10 ** 27;
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
         
        z = mul(x, y) / RAY;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
         
        z = mul(x, RAY) / y;
    }
    function rdivup(uint x, uint y) internal pure returns (uint z) {
         
        z = add(mul(x, RAY), sub(y, 1)) / y;
    }

     
    bytes32 public constant DOMAIN_SEPARATOR = 0x0b50407de9fa158c2cba01a99633329490dfd22989a150c20e8c7b4c1fb0fcc3;
     
    bytes32 public constant PERMIT_TYPEHASH  = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    constructor() public {
        assert (DOMAIN_SEPARATOR ==
          keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)), keccak256(bytes(version)), 1, address(this)))
        );

        vat.hope(address(daiJoin));
        vat.hope(address(pot));

        daiToken.approve(address(daiJoin), uint(-1));
    }

     
    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }
     
    function move(address src, address dst, uint wad) external returns (bool) {
        uint chi = (now > pot.rho()) ? pot.drip() : pot.chi();
         
        return transferFrom(src, dst, rdivup(wad, chi));
    }
    function transferFrom(address src, address dst, uint wad)
        public returns (bool)
    {
        require(balanceOf[src] >= wad, "chai/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad, "chai/insufficient-allowance");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }
    function approve(address usr, uint wad) external returns (bool) {
        allowance[msg.sender][usr] = wad;
        emit Approval(msg.sender, usr, wad);
        return true;
    }

     
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external
    {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(PERMIT_TYPEHASH,
                                 holder,
                                 spender,
                                 nonce,
                                 expiry,
                                 allowed))));
        require(holder != address(0), "chai/invalid holder");
        require(holder == ecrecover(digest, v, r, s), "chai/invalid-permit");
        require(expiry == 0 || now <= expiry, "chai/permit-expired");
        require(nonce == nonces[holder]++, "chai/invalid-nonce");

        uint can = allowed ? uint(-1) : 0;
        allowance[holder][spender] = can;
        emit Approval(holder, spender, can);
    }

    function dai(address usr) external returns (uint wad) {
        uint chi = (now > pot.rho()) ? pot.drip() : pot.chi();
        wad = rmul(chi, balanceOf[usr]);
    }
     
    function join(address dst, uint wad) external {
        uint chi = (now > pot.rho()) ? pot.drip() : pot.chi();
        uint pie = rdiv(wad, chi);
        balanceOf[dst] = add(balanceOf[dst], pie);
        totalSupply    = add(totalSupply, pie);

        daiToken.transferFrom(msg.sender, address(this), wad);
        daiJoin.join(address(this), wad);
        pot.join(pie);
        emit Transfer(address(0), dst, pie);
    }

     
    function exit(address src, uint wad) public {
        require(balanceOf[src] >= wad, "chai/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad, "chai/insufficient-allowance");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }
        balanceOf[src] = sub(balanceOf[src], wad);
        totalSupply    = sub(totalSupply, wad);

        uint chi = (now > pot.rho()) ? pot.drip() : pot.chi();
        pot.exit(wad);
        daiJoin.exit(msg.sender, rmul(chi, wad));
        emit Transfer(src, address(0), wad);
    }

     
    function draw(address src, uint wad) external {
        uint chi = (now > pot.rho()) ? pot.drip() : pot.chi();
         
        exit(src, rdivup(wad, chi));
    }
}