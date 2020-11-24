 

 

pragma solidity ^0.5.0;

 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

 

pragma solidity ^0.5.0;

 
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity 0.5.13;



contract ERC721 {
    function transferFrom(address from, address to, uint256 tokenId) public;
}


 
contract SecretSanta is Ownable {
    address public lastSecretSanta;

    uint256 public lastPresentAt;
    uint256 public prizeDelay;

    address[] public prizeTokens;
    uint256[] public prizeTokensId;

    mapping (address => bool) public whitelist;

    event PresentSent(
        address indexed from,
        address indexed to,
        address token,
        uint256 tokenId
    );

    event PrizeAdded(
        address indexed from,
        address[] tokens,
        uint256[] tokensId
    );

    constructor(
        uint256 initialPrizeDelay
    ) public {
        lastSecretSanta = msg.sender;
        lastPresentAt = now;
        prizeDelay = initialPrizeDelay;
    }

     
    function sendPrize(
        address[] calldata tokens,
        uint256[] calldata tokensId
    ) external {
        require(
            tokens.length == tokensId.length,
            "Invalid array"
        );

        require(
            lastPresentAt + prizeDelay > now,
            "Too late"
        );

        for (uint256 i = 0; i < tokens.length; i += 1) {
            require(
                whitelist[tokens[i]],
                "Token not whitelisted"
            );

            ERC721 token = ERC721(tokens[i]);

            token.transferFrom(
                msg.sender,
                address(this),
                tokensId[i]
            );

            prizeTokens.push(tokens[i]);
            prizeTokensId.push(tokensId[i]);
        }

        emit PrizeAdded(
            msg.sender,
            tokens,
            tokensId
        );
    }

     
    function sendPresent(
        address tokenAddress,
        uint256 tokenId
    ) external {
        require(
            lastPresentAt + prizeDelay > now,
            "Too late"
        );

        require(
            whitelist[tokenAddress],
            "Token not whitelisted"
        );

        ERC721 token = ERC721(tokenAddress);

        token.transferFrom(
            msg.sender,
            lastSecretSanta,
            tokenId
        );

        emit PresentSent(
            msg.sender,
            lastSecretSanta,
            tokenAddress,
            tokenId
        );

        lastSecretSanta = msg.sender;
        lastPresentAt = now;
    }

     
    function claimPrize(
        address[] calldata tokens,
        uint256[] calldata tokensId
    ) external {
        require(
            now > lastPresentAt + prizeDelay,
            "Not yet"
        );

        require(
            msg.sender == lastSecretSanta,
            "Sender not last Santa"
        );

        for (uint256 i = 0; i < tokens.length; i += 1) {
            ERC721 token = ERC721(tokens[i]);

            token.transferFrom(
                address(this),
                msg.sender,
                tokensId[i]
            );
        }
    }

    function updateWhitelist(
        address[] calldata tokens,
        bool isApproved
    ) external onlyOwner() {
        for (uint256 i = 0; i < tokens.length; i += 1) {
            whitelist[tokens[i]] = isApproved;
        }
    }

    function getPrize() external view returns (
        address[] memory tokens,
        uint256[] memory tokensId
    ) {
        return (
            prizeTokens,
            prizeTokensId
        );
    }

    function isTooLate() external view returns (bool) {
        return now > lastPresentAt + prizeDelay;
    }
}