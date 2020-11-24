 
contract StickerMarket is Controlled, TokenClaimer, ApproveAndCallFallBack {
    using SafeMath for uint256;
    
    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event MarketState(State state);
    event RegisterFee(uint256 value);
    event BurnRate(uint256 value);

    enum State { Invalid, Open, BuyOnly, Controlled, Closed }

    State public state = State.Open;
    uint256 registerFee;
    uint256 burnRate;
    
     
    ERC20Token public snt;  
    StickerPack public stickerPack;
    StickerType public stickerType;
    
     
    modifier marketManagement {
        require(state == State.Open || (msg.sender == controller && state == State.Controlled), "Market Disabled");
        _;
    }

     
    modifier marketSell {
        require(state == State.Open || state == State.BuyOnly || (msg.sender == controller && state == State.Controlled), "Market Disabled");
        _;
    }

     
    constructor(
        ERC20Token _snt,
        StickerPack _stickerPack,
        StickerType _stickerType
    ) 
        public
    { 
        require(address(_snt) != address(0), "Bad _snt parameter");
        require(address(_stickerPack) != address(0), "Bad _stickerPack parameter");
        require(address(_stickerType) != address(0), "Bad _stickerType parameter");
        snt = _snt;
        stickerPack = _stickerPack;
        stickerType = _stickerType;
    }

     
    function buyToken(
        uint256 _packId,
        address _destination,
        uint256 _price
    ) 
        external  
        returns (uint256 tokenId)
    {
        return buy(msg.sender, _packId, _destination, _price);
    }

     
    function registerPack(
        uint256 _price,
        uint256 _donate,
        bytes4[] calldata _category, 
        address _owner,
        bytes calldata _contenthash,
        uint256 _fee
    ) 
        external  
        returns(uint256 packId)
    {
        packId = register(msg.sender, _category, _owner, _price, _donate, _contenthash, _fee);
    }

     
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes calldata _data
    ) 
        external 
    {
        require(_token == address(snt), "Bad token");
        require(_token == address(msg.sender), "Bad call");
        bytes4 sig = abiDecodeSig(_data);
        bytes memory cdata = slice(_data,4,_data.length-4);
        if(sig == this.buyToken.selector){
            require(cdata.length == 96, "Bad data length");
            (uint256 packId, address owner, uint256 price) = abi.decode(cdata, (uint256, address, uint256));
            require(_value == price, "Bad price value");
            buy(_from, packId, owner, price);
        } else if(sig == this.registerPack.selector) {
            require(cdata.length >= 188, "Bad data length");
            (uint256 price, uint256 donate, bytes4[] memory category, address owner, bytes memory contenthash, uint256 fee) = abi.decode(cdata, (uint256,uint256,bytes4[],address,bytes,uint256));
            require(_value == fee, "Bad fee value");
            register(_from, category, owner, price, donate, contenthash, fee);
        } else {
            revert("Bad call");
        }
    }

     
    function setMarketState(State _state)
        external
        onlyController 
    {
        state = _state;
        emit MarketState(_state);
    }

     
    function setRegisterFee(uint256 _value)
        external
        onlyController 
    {
        registerFee = _value;
        emit RegisterFee(_value);
    }

     
    function setBurnRate(uint256 _value)
        external
        onlyController 
    {
        burnRate = _value;
        require(_value <= 10000, "cannot be more then 100.00%");
        emit BurnRate(_value);
    }
    
     
    function generatePack(
        uint256 _price,
        uint256 _donate,
        bytes4[] calldata _category, 
        address _owner,
        bytes calldata _contenthash
    ) 
        external  
        onlyController
        returns(uint256 packId)
    {
        packId = stickerType.generatePack(_price, _donate, _category, _owner, _contenthash);
    }

     
    function purgePack(uint256 _packId, uint256 _limit)
        external
        onlyController 
    {
        stickerType.purgePack(_packId, _limit);
    }

     
    function generateToken(address _owner, uint256 _packId) 
        external
        onlyController 
        returns (uint256 tokenId)
    {
        return stickerPack.generateToken(_owner, _packId);
    }

     
    function migrate(address payable _newController) 
        external
        onlyController 
    {
        require(_newController != address(0), "Cannot unset controller");
        stickerType.changeController(_newController);
        stickerPack.changeController(_newController);
    }

     
    function claimTokens(address _token) 
        external
        onlyController 
    {
        withdrawBalance(_token, controller);
    }

     
    function getTokenData(uint256 _tokenId) 
        external 
        view 
        returns (
            bytes4[] memory category,
            uint256 timestamp,
            bytes memory contenthash
        ) 
    {
        return stickerType.getPackSummary(stickerPack.tokenPackId(_tokenId));
    }

     
    function register(
        address _caller,
        bytes4[] memory _category,
        address _owner,
        uint256 _price,
        uint256 _donate,
        bytes memory _contenthash,
        uint256 _fee
    ) 
        internal 
        marketManagement
        returns(uint256 packId) 
    {
        require(_fee == registerFee, "Unexpected fee");
        if(registerFee > 0){
            require(snt.transferFrom(_caller, controller, registerFee), "Bad payment");
        }
        packId = stickerType.generatePack(_price, _donate, _category, _owner, _contenthash);
    }

     
    function buy(
        address _caller,
        uint256 _packId,
        address _destination,
        uint256 _price
    ) 
        internal 
        marketSell
        returns (uint256 tokenId)
    {
        (
            address pack_owner,
            bool pack_mintable,
            uint256 pack_price,
            uint256 pack_donate
        ) = stickerType.getPaymentData(_packId);
        require(pack_owner != address(0), "Bad pack");
        require(pack_mintable, "Disabled");
        uint256 amount = pack_price;
        require(_price == amount, "Wrong price");
        require(amount > 0, "Unauthorized");
        if(amount > 0 && burnRate > 0) {
            uint256 burned = amount.mul(burnRate).div(10000);
            amount = amount.sub(burned);
            require(snt.transferFrom(_caller, Controlled(address(snt)).controller(), burned), "Bad burn");
        }
        if(amount > 0 && pack_donate > 0) {
            uint256 donate = amount.mul(pack_donate).div(10000);
            amount = amount.sub(donate);
            require(snt.transferFrom(_caller, controller, donate), "Bad donate");
        } 
        if(amount > 0) {
            require(snt.transferFrom(_caller, pack_owner, amount), "Bad payment");
        }
        return stickerPack.generateToken(_destination, _packId);
    }

     
    function abiDecodeSig(bytes memory _data) private pure returns(bytes4 sig){
        assembly {
            sig := mload(add(_data, add(0x20, 0)))
        }
    }

     
    function slice(bytes memory _bytes, uint _start, uint _length) private pure returns (bytes memory) {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                 
                 
                tempBytes := mload(0x40)

                 
                 
                 
                 
                 
                 
                 
                 
                let lengthmod := and(_length, 31)

                 
                 
                 
                 
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                     
                     
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                 
                 
                mstore(0x40, and(add(mc, 31), not(31)))
            }
             
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }


     
     
    event Register(uint256 indexed packId, uint256 dataPrice, bytes contenthash);
     
      event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed value
    );
}