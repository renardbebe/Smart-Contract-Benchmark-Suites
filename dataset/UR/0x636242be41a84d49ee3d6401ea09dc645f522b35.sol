 

 
pragma solidity =0.5.12;

 
 
 
 
 

 
 
 
 

 
 

 

contract LibNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  usr,
        bytes32  indexed  arg1,
        bytes32  indexed  arg2,
        bytes             data
    ) anonymous;

    modifier note {
        _;
        assembly {
             
             
            let mark := msize                          
            mstore(0x40, add(mark, 288))               
            mstore(mark, 0x20)                         
            mstore(add(mark, 0x20), 224)               
            calldatacopy(add(mark, 0x40), 0, 224)      
            log4(mark, 288,                            
                 shl(224, shr(224, calldataload(0))),  
                 caller,                               
                 calldataload(4),                      
                 calldataload(36)                      
                )
        }
    }
}

 
 

 
 
 
 
 
 
 
 
 
 
 
 
 
 

 

 

contract VatLike {
    function slip(bytes32,address,int) public;
}

 

 
 

contract GemLike2 {
    function decimals() public view returns (uint);
    function transfer(address,uint) public;
    function transferFrom(address,address,uint) public;
    function balanceOf(address) public view returns (uint);
    function allowance(address,address) public view returns (uint);
}

contract GemJoin2 is LibNote {
     
    mapping (address => uint) public wards;
    function rely(address usr) external note auth { wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    VatLike  public vat;
    bytes32  public ilk;
    GemLike2 public gem;
    uint     public dec;
    uint     public live;   

    constructor(address vat_, bytes32 ilk_, address gem_) public {
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike(vat_);
        ilk = ilk_;
        gem = GemLike2(gem_);
        dec = gem.decimals();
    }

    function cage() external note auth {
        live = 0;
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "GemJoin2/overflow");
    }

    function join(address urn, uint wad) public note {
        require(live == 1, "GemJoin2/not-live");
        require(wad <= 2 ** 255, "GemJoin2/overflow");
        vat.slip(ilk, urn, int(wad));
        uint256 prevBalance = gem.balanceOf(msg.sender);

        require(prevBalance >= wad, "GemJoin2/no-funds");
        require(gem.allowance(msg.sender, address(this)) >= wad, "GemJoin2/no-allowance");

        (bool ok,) = address(gem).call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), wad)
        );
        require(ok, "GemJoin2/failed-transfer");

        require(prevBalance - wad == gem.balanceOf(msg.sender), "GemJoin2/failed-transfer");
    }

    function exit(address guy, uint wad) public note {
        require(wad <= 2 ** 255, "GemJoin2/overflow");
        vat.slip(ilk, msg.sender, -int(wad));
        uint256 prevBalance = gem.balanceOf(address(this));

        require(prevBalance >= wad, "GemJoin2/no-funds");

        (bool ok,) = address(gem).call(
            abi.encodeWithSignature("transfer(address,uint256)", guy, wad)
        );
        require(ok, "GemJoin2/failed-transfer");

        require(prevBalance - wad == gem.balanceOf(address(this)), "GemJoin2/failed-transfer");
    }
}

 
 

contract GemLike3 {
    function transfer(address,uint) public returns (bool);
    function transferFrom(address,address,uint) public returns (bool);
}

contract GemJoin3 is LibNote {
     
    mapping (address => uint) public wards;
    function rely(address usr) external note auth { wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    VatLike  public vat;
    bytes32  public ilk;
    GemLike3 public gem;
    uint     public dec;
    uint     public live;   

    constructor(address vat_, bytes32 ilk_, address gem_, uint decimals) public {
        require(decimals < 18, "GemJoin3/decimals-18-or-higher");
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike(vat_);
        ilk = ilk_;
        gem = GemLike3(gem_);
        dec = decimals;
    }

    function cage() external note auth {
        live = 0;
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "GemJoin3/overflow");
    }

    function join(address urn, uint wad) public note {
        require(live == 1, "GemJoin3/not-live");
        uint wad18 = mul(wad, 10 ** (18 - dec));
        require(wad18 <= 2 ** 255, "GemJoin3/overflow");
        vat.slip(ilk, urn, int(wad18));
        require(gem.transferFrom(msg.sender, address(this), wad), "GemJoin3/failed-transfer");
    }

    function exit(address guy, uint wad) public note {
        uint wad18 = mul(wad, 10 ** (18 - dec));
        require(wad18 <= 2 ** 255, "GemJoin3/overflow");
        vat.slip(ilk, msg.sender, -int(wad18));
        require(gem.transfer(guy, wad), "GemJoin3/failed-transfer");
    }
}

 

 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
 
 

 
 

 
 
 

contract GemLike4 {
    function decimals() public view returns (uint);
    function balanceOf(address) public returns (uint256);
    function transfer(address, uint256) public returns (bool);
}

contract GemBag {
    address  public ada;
    address  public lad;
    GemLike4 public gem;

    constructor(address lad_, address gem_) public {
        ada = msg.sender;
        lad = lad_;
        gem = GemLike4(gem_);
    }

    function exit(address usr, uint256 wad) external {
        require(msg.sender == ada || msg.sender == lad, "GemBag/invalid-caller");
        require(gem.transfer(usr, wad), "GemBag/failed-transfer");
    }
}

contract GemJoin4 is LibNote {
     
    mapping (address => uint) public wards;
    function rely(address usr) external note auth { wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    VatLike  public vat;
    bytes32  public ilk;
    GemLike4 public gem;
    uint     public dec;
    uint     public live;   

    mapping(address => address) public bags;

    constructor(address vat_, bytes32 ilk_, address gem_) public {
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike(vat_);
        ilk = ilk_;
        gem = GemLike4(gem_);
        dec = gem.decimals();
    }

    function cage() external note auth {
        live = 0;
    }

     
    function make() external returns (address bag) {
        bag = make(msg.sender);
    }

    function make(address usr) public note returns (address bag) {
        require(bags[usr] == address(0), "GemJoin4/bag-already-exists");

        bag = address(new GemBag(address(usr), address(gem)));
        bags[usr] = bag;
    }

     
    function join(address urn, uint256 wad) external note {
        require(live == 1, "GemJoin4/not-live");
        require(int256(wad) >= 0, "GemJoin4/negative-amount");

        GemBag(bags[msg.sender]).exit(address(this), wad);
        vat.slip(ilk, urn, int256(wad));
    }

    function exit(address usr, uint256 wad) external note {
        require(int256(wad) >= 0, "GemJoin4/negative-amount");

        vat.slip(ilk, msg.sender, -int256(wad));
        require(gem.transfer(usr, wad), "GemJoin4/failed-transfer");
    }
}

 
 

contract GemLike {
    function decimals() public view returns (uint);
    function transfer(address,uint) public returns (bool);
    function transferFrom(address,address,uint) public returns (bool);
}

contract AuthGemJoin is LibNote {
    VatLike public vat;
    bytes32 public ilk;
    GemLike public gem;
    uint    public dec;
    uint    public live;   

     
    mapping (address => uint) public wards;
    function rely(address usr) public note auth { wards[usr] = 1; }
    function deny(address usr) public note auth { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1, "AuthGemJoin/non-authed"); _; }

    constructor(address vat_, bytes32 ilk_, address gem_) public {
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike(vat_);
        ilk = ilk_;
        gem = GemLike(gem_);
        dec = gem.decimals();
    }

    function cage() external note auth {
        live = 0;
    }

    function join(address usr, uint wad) public auth note {
        require(live == 1, "AuthGemJoin/not-live");
        require(int(wad) >= 0, "AuthGemJoin/overflow");
        vat.slip(ilk, usr, int(wad));
        require(gem.transferFrom(msg.sender, address(this), wad), "AuthGemJoin/failed-transfer");
    }

    function exit(address usr, uint wad) public note {
        require(wad <= 2 ** 255, "AuthGemJoin/overflow");
        vat.slip(ilk, msg.sender, -int(wad));
        require(gem.transfer(usr, wad), "AuthGemJoin/failed-transfer");
    }
}