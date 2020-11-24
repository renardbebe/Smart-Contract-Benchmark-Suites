 

pragma solidity ^0.4.11;


 
 
contract ERC721 {
     
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

     
     
     
     
     

     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}



 
contract Ownable {
    address public owner;


     
    function Ownable() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}




 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        Pause();
        return true;
    }

     
    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        Unpause();
        return true;
    }
}






 
 
 
contract ClockAuctionBase {

     
    struct Auction {
         
        address seller;
         
        uint128 startingPrice;
         
        uint128 endingPrice;
         
        uint64 duration;
         
         
        uint64 startedAt;
    }

     
    ERC721 public nonFungibleContract;

     
     
    uint256 public ownerCut;

     
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

     
     
     
     
    function _escrow(address _owner, uint256 _tokenId) internal {
         
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

     
     
     
     
    function _transfer(address _receiver, uint256 _tokenId) internal {
         
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

     
     
     
     
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
         
         
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

     
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        AuctionCancelled(_tokenId);
    }

     
     
    function _bid(uint256 _tokenId, uint256 _bidAmount)
    internal
    returns (uint256)
    {
         
        Auction storage auction = tokenIdToAuction[_tokenId];

         
         
         
         
        require(_isOnAuction(auction));

         
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

         
         
        address seller = auction.seller;

         
         
        _removeAuction(_tokenId);

         
        if (price > 0) {
             
             
             
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

             
             
             
             
             
             
             
             
            seller.transfer(sellerProceeds);
        }

         
         
         
         
        uint256 bidExcess = _bidAmount - price;

         
         
         
        msg.sender.transfer(bidExcess);

         
        AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }

     
     
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

     
     
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

     
     
     
     
    function _currentPrice(Auction storage _auction)
    internal
    view
    returns (uint256)
    {
        uint256 secondsPassed = 0;

         
         
         
        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondsPassed
        );
    }

     
     
     
     
    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
    internal
    pure
    returns (uint256)
    {
         
         
         
         
         
        if (_secondsPassed >= _duration) {
             
             
            return _endingPrice;
        } else {
             
             
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

             
             
             
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

             
             
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

     
     
    function _computeCut(uint256 _price) internal view returns (uint256) {
         
         
         
         
         
        return _price * ownerCut / 10000;
    }

}





 
 
contract ClockAuction is Pausable, ClockAuctionBase {

     
     
     
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);

     
     
     
     
     
     
    function ClockAuction(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nonFungibleContract = candidateContract;
    }

     
     
     
     
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
         
        nftAddress.transfer(this.balance);
    }

     
     
     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
    external
    whenNotPaused
    {
         
         
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(_owns(msg.sender, _tokenId));
        _escrow(msg.sender, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

     
     
     
    function bid(uint256 _tokenId)
    external
    payable
    whenNotPaused
    {
         
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

     
     
     
     
     
    function cancelAuction(uint256 _tokenId)
    external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

     
     
     
     
    function cancelAuctionWhenPaused(uint256 _tokenId)
    whenPaused
    onlyOwner
    external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

     
     
    function getAuction(uint256 _tokenId)
    external
    view
    returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
        auction.seller,
        auction.startingPrice,
        auction.endingPrice,
        auction.duration,
        auction.startedAt
        );
    }

     
     
    function getCurrentPrice(uint256 _tokenId)
    external
    view
    returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

}

 
contract GeneScience {

    uint64 _seed = 0;

     
     
    function isGeneScience() public pure returns (bool) {
        return true;
    }

     
     
    function random(uint64 upper) internal returns (uint64) {
        _seed = uint64(keccak256(keccak256(block.blockhash(block.number), _seed), now));
        return _seed % upper;
    }

    function randomBetween(uint32 a, uint32 b) internal returns (uint32) {
        uint32 min;
        uint32 max;
        if(a < b) {
            min = a;
            max = b;
        } else {
            min = b;
            max = a;
        }

        return min + uint32(random(max - min + 1));
    }

    function randomCode() internal returns (uint8) {
         
        uint64 r = random(1000000);

        if (r <= 163) return 151;
        if (r <= 327) return 251;
        if (r <= 490) return 196;
        if (r <= 654) return 197;
        if (r <= 817) return 238;
        if (r <= 981) return 240;
        if (r <= 1144) return 239;
        if (r <= 1308) return 173;
        if (r <= 1471) return 175;
        if (r <= 1635) return 174;
        if (r <= 1798) return 236;
        if (r <= 1962) return 172;
        if (r <= 2289) return 250;
        if (r <= 2616) return 249;
        if (r <= 2943) return 244;
        if (r <= 3270) return 243;
        if (r <= 3597) return 245;
        if (r <= 4087) return 145;
        if (r <= 4577) return 146;
        if (r <= 5068) return 144;
        if (r <= 5885) return 248;
        if (r <= 6703) return 149;
        if (r <= 7520) return 143;
        if (r <= 8337) return 112;
        if (r <= 9155) return 242;
        if (r <= 9972) return 212;
        if (r <= 10790) return 160;
        if (r <= 11607) return 6;
        if (r <= 12424) return 157;
        if (r <= 13242) return 131;
        if (r <= 14059) return 3;
        if (r <= 14877) return 233;
        if (r <= 15694) return 9;
        if (r <= 16511) return 154;
        if (r <= 17329) return 182;
        if (r <= 18146) return 176;
        if (r <= 19127) return 150;
        if (r <= 20762) return 130;
        if (r <= 22397) return 68;
        if (r <= 24031) return 65;
        if (r <= 25666) return 59;
        if (r <= 27301) return 94;
        if (r <= 28936) return 199;
        if (r <= 30571) return 169;
        if (r <= 32205) return 208;
        if (r <= 33840) return 230;
        if (r <= 35475) return 186;
        if (r <= 37110) return 36;
        if (r <= 38744) return 38;
        if (r <= 40379) return 192;
        if (r <= 42014) return 26;
        if (r <= 43649) return 237;
        if (r <= 45284) return 148;
        if (r <= 46918) return 247;
        if (r <= 48553) return 2;
        if (r <= 50188) return 5;
        if (r <= 51823) return 8;
        if (r <= 53785) return 134;
        if (r <= 55746) return 232;
        if (r <= 57708) return 76;
        if (r <= 59670) return 136;
        if (r <= 61632) return 135;
        if (r <= 63593) return 181;
        if (r <= 65555) return 62;
        if (r <= 67517) return 34;
        if (r <= 69479) return 31;
        if (r <= 71440) return 221;
        if (r <= 73402) return 71;
        if (r <= 75364) return 185;
        if (r <= 77325) return 18;
        if (r <= 79287) return 15;
        if (r <= 81249) return 12;
        if (r <= 83211) return 159;
        if (r <= 85172) return 189;
        if (r <= 87134) return 219;
        if (r <= 89096) return 156;
        if (r <= 91058) return 153;
        if (r <= 93510) return 217;
        if (r <= 95962) return 139;
        if (r <= 98414) return 229;
        if (r <= 100866) return 141;
        if (r <= 103319) return 210;
        if (r <= 105771) return 45;
        if (r <= 108223) return 205;
        if (r <= 110675) return 78;
        if (r <= 113127) return 224;
        if (r <= 115580) return 171;
        if (r <= 118032) return 164;
        if (r <= 120484) return 178;
        if (r <= 122936) return 195;
        if (r <= 125388) return 105;
        if (r <= 127840) return 162;
        if (r <= 130293) return 168;
        if (r <= 132745) return 184;
        if (r <= 135197) return 166;
        if (r <= 138467) return 103;
        if (r <= 141736) return 89;
        if (r <= 145006) return 99;
        if (r <= 148275) return 142;
        if (r <= 151545) return 80;
        if (r <= 154814) return 91;
        if (r <= 158084) return 115;
        if (r <= 161354) return 106;
        if (r <= 164623) return 73;
        if (r <= 167893) return 28;
        if (r <= 171162) return 241;
        if (r <= 174432) return 121;
        if (r <= 177701) return 55;
        if (r <= 180971) return 126;
        if (r <= 184241) return 82;
        if (r <= 187510) return 125;
        if (r <= 190780) return 110;
        if (r <= 194049) return 85;
        if (r <= 197319) return 57;
        if (r <= 200589) return 107;
        if (r <= 203858) return 97;
        if (r <= 207128) return 119;
        if (r <= 210397) return 227;
        if (r <= 213667) return 117;
        if (r <= 216936) return 49;
        if (r <= 220206) return 40;
        if (r <= 223476) return 101;
        if (r <= 226745) return 87;
        if (r <= 230015) return 215;
        if (r <= 233284) return 42;
        if (r <= 236554) return 22;
        if (r <= 239823) return 207;
        if (r <= 243093) return 24;
        if (r <= 246363) return 93;
        if (r <= 249632) return 47;
        if (r <= 252902) return 20;
        if (r <= 256171) return 53;
        if (r <= 259441) return 113;
        if (r <= 262710) return 198;
        if (r <= 265980) return 51;
        if (r <= 269250) return 108;
        if (r <= 272519) return 190;
        if (r <= 275789) return 158;
        if (r <= 279058) return 95;
        if (r <= 282328) return 1;
        if (r <= 285598) return 225;
        if (r <= 288867) return 4;
        if (r <= 292137) return 155;
        if (r <= 295406) return 7;
        if (r <= 298676) return 152;
        if (r <= 301945) return 25;
        if (r <= 305215) return 132;
        if (r <= 309302) return 67;
        if (r <= 313389) return 64;
        if (r <= 317476) return 75;
        if (r <= 321563) return 70;
        if (r <= 325650) return 180;
        if (r <= 329737) return 61;
        if (r <= 333824) return 33;
        if (r <= 337911) return 30;
        if (r <= 341998) return 17;
        if (r <= 346085) return 202;
        if (r <= 350172) return 188;
        if (r <= 354259) return 11;
        if (r <= 358346) return 14;
        if (r <= 362433) return 235;
        if (r <= 367337) return 214;
        if (r <= 372241) return 127;
        if (r <= 377146) return 124;
        if (r <= 382050) return 128;
        if (r <= 386954) return 123;
        if (r <= 391859) return 226;
        if (r <= 396763) return 234;
        if (r <= 401667) return 122;
        if (r <= 406572) return 211;
        if (r <= 411476) return 203;
        if (r <= 416381) return 200;
        if (r <= 421285) return 206;
        if (r <= 426189) return 44;
        if (r <= 431094) return 193;
        if (r <= 435998) return 222;
        if (r <= 440902) return 58;
        if (r <= 445807) return 83;
        if (r <= 450711) return 35;
        if (r <= 455615) return 201;
        if (r <= 460520) return 37;
        if (r <= 465424) return 218;
        if (r <= 470329) return 220;
        if (r <= 475233) return 213;
        if (r <= 481772) return 114;
        if (r <= 488311) return 137;
        if (r <= 494850) return 77;
        if (r <= 501390) return 138;
        if (r <= 507929) return 140;
        if (r <= 514468) return 209;
        if (r <= 521007) return 228;
        if (r <= 527546) return 170;
        if (r <= 534085) return 204;
        if (r <= 540624) return 92;
        if (r <= 547164) return 133;
        if (r <= 553703) return 104;
        if (r <= 560242) return 177;
        if (r <= 566781) return 246;
        if (r <= 573320) return 147;
        if (r <= 579859) return 46;
        if (r <= 586399) return 194;
        if (r <= 594573) return 111;
        if (r <= 602746) return 98;
        if (r <= 610920) return 88;
        if (r <= 619094) return 79;
        if (r <= 627268) return 66;
        if (r <= 635442) return 27;
        if (r <= 643616) return 74;
        if (r <= 651790) return 216;
        if (r <= 659964) return 231;
        if (r <= 668138) return 63;
        if (r <= 676312) return 102;
        if (r <= 684486) return 109;
        if (r <= 692660) return 81;
        if (r <= 700834) return 84;
        if (r <= 709008) return 118;
        if (r <= 717182) return 56;
        if (r <= 725356) return 96;
        if (r <= 733530) return 54;
        if (r <= 741703) return 90;
        if (r <= 749877) return 72;
        if (r <= 758051) return 120;
        if (r <= 766225) return 116;
        if (r <= 774399) return 69;
        if (r <= 782573) return 48;
        if (r <= 790747) return 86;
        if (r <= 798921) return 179;
        if (r <= 807095) return 100;
        if (r <= 815269) return 23;
        if (r <= 823443) return 223;
        if (r <= 831617) return 32;
        if (r <= 839791) return 29;
        if (r <= 847965) return 39;
        if (r <= 856139) return 60;
        if (r <= 864313) return 167;
        if (r <= 872487) return 21;
        if (r <= 880660) return 165;
        if (r <= 888834) return 163;
        if (r <= 897008) return 52;
        if (r <= 905182) return 19;
        if (r <= 913356) return 16;
        if (r <= 921530) return 41;
        if (r <= 929704) return 161;
        if (r <= 937878) return 187;
        if (r <= 946052) return 50;
        if (r <= 954226) return 183;
        if (r <= 962400) return 13;
        if (r <= 970574) return 10;
        if (r <= 978748) return 191;
        if (r <= 988556) return 43;
        if (r <= 1000000) return 129;

        return 129;
    }

    function getBaseStats(uint8 id) public pure returns (uint32 ra, uint32 rd, uint32 rs) {
        if (id == 151) return (210, 210, 200);
        if (id == 251) return (210, 210, 200);
        if (id == 196) return (261, 194, 130);
        if (id == 197) return (126, 250, 190);
        if (id == 238) return (153, 116, 90);
        if (id == 240) return (151, 108, 90);
        if (id == 239) return (135, 110, 90);
        if (id == 173) return (75, 91, 100);
        if (id == 175) return (67, 116, 70);
        if (id == 174) return (69, 34, 180);
        if (id == 236) return (64, 64, 70);
        if (id == 172) return (77, 63, 40);
        if (id == 250) return (239, 274, 193);
        if (id == 249) return (193, 323, 212);
        if (id == 244) return (235, 176, 230);
        if (id == 243) return (241, 210, 180);
        if (id == 245) return (180, 235, 200);
        if (id == 145) return (253, 188, 180);
        if (id == 146) return (251, 184, 180);
        if (id == 144) return (192, 249, 180);
        if (id == 248) return (251, 212, 200);
        if (id == 149) return (263, 201, 182);
        if (id == 143) return (190, 190, 320);
        if (id == 112) return (222, 206, 210);
        if (id == 242) return (129, 229, 510);
        if (id == 212) return (236, 191, 140);
        if (id == 160) return (205, 197, 170);
        if (id == 6) return (223, 176, 156);
        if (id == 157) return (223, 176, 156);
        if (id == 131) return (165, 180, 260);
        if (id == 3) return (198, 198, 160);
        if (id == 233) return (198, 183, 170);
        if (id == 9) return (171, 210, 158);
        if (id == 154) return (168, 202, 160);
        if (id == 182) return (169, 189, 150);
        if (id == 176) return (139, 191, 110);
        if (id == 150) return (300, 182, 193);
        if (id == 130) return (237, 197, 190);
        if (id == 68) return (234, 162, 180);
        if (id == 65) return (271, 194, 110);
        if (id == 59) return (227, 166, 180);
        if (id == 94) return (261, 156, 120);
        if (id == 199) return (177, 194, 190);
        if (id == 169) return (194, 178, 170);
        if (id == 208) return (148, 333, 150);
        if (id == 230) return (194, 194, 150);
        if (id == 186) return (174, 192, 180);
        if (id == 36) return (178, 171, 190);
        if (id == 38) return (169, 204, 146);
        if (id == 192) return (185, 148, 150);
        if (id == 26) return (193, 165, 120);
        if (id == 237) return (173, 214, 100);
        if (id == 148) return (163, 138, 122);
        if (id == 247) return (155, 133, 140);
        if (id == 2) return (151, 151, 120);
        if (id == 5) return (158, 129, 116);
        if (id == 8) return (126, 155, 118);
        if (id == 134) return (205, 177, 260);
        if (id == 232) return (214, 214, 180);
        if (id == 76) return (211, 229, 160);
        if (id == 136) return (246, 204, 130);
        if (id == 135) return (232, 201, 130);
        if (id == 181) return (211, 172, 180);
        if (id == 62) return (182, 187, 180);
        if (id == 34) return (204, 157, 162);
        if (id == 31) return (180, 174, 180);
        if (id == 221) return (181, 147, 200);
        if (id == 71) return (207, 138, 160);
        if (id == 185) return (167, 198, 140);
        if (id == 18) return (166, 157, 166);
        if (id == 15) return (169, 150, 130);
        if (id == 12) return (167, 151, 120);
        if (id == 159) return (150, 151, 130);
        if (id == 189) return (118, 197, 150);
        if (id == 219) return (139, 209, 100);
        if (id == 156) return (158, 129, 116);
        if (id == 153) return (122, 155, 120);
        if (id == 217) return (236, 144, 180);
        if (id == 139) return (207, 227, 140);
        if (id == 229) return (224, 159, 150);
        if (id == 141) return (220, 203, 120);
        if (id == 210) return (212, 137, 180);
        if (id == 45) return (202, 170, 150);
        if (id == 205) return (161, 242, 150);
        if (id == 78) return (207, 167, 130);
        if (id == 224) return (197, 141, 150);
        if (id == 171) return (146, 146, 250);
        if (id == 164) return (145, 179, 200);
        if (id == 178) return (192, 146, 130);
        if (id == 195) return (152, 152, 190);
        if (id == 105) return (144, 200, 120);
        if (id == 162) return (148, 130, 170);
        if (id == 168) return (161, 128, 140);
        if (id == 184) return (112, 152, 200);
        if (id == 166) return (107, 209, 110);
        if (id == 103) return (233, 158, 190);
        if (id == 89) return (190, 184, 210);
        if (id == 99) return (240, 214, 110);
        if (id == 142) return (221, 164, 160);
        if (id == 80) return (177, 194, 190);
        if (id == 91) return (186, 323, 100);
        if (id == 115) return (181, 165, 210);
        if (id == 106) return (224, 211, 100);
        if (id == 73) return (166, 237, 160);
        if (id == 28) return (182, 202, 150);
        if (id == 241) return (157, 211, 190);
        if (id == 121) return (210, 184, 120);
        if (id == 55) return (191, 163, 160);
        if (id == 126) return (206, 169, 130);
        if (id == 82) return (223, 182, 100);
        if (id == 125) return (198, 173, 130);
        if (id == 110) return (174, 221, 130);
        if (id == 85) return (218, 145, 120);
        if (id == 57) return (207, 144, 130);
        if (id == 107) return (193, 212, 100);
        if (id == 97) return (144, 215, 170);
        if (id == 119) return (175, 154, 160);
        if (id == 227) return (148, 260, 130);
        if (id == 117) return (187, 182, 110);
        if (id == 49) return (179, 150, 140);
        if (id == 40) return (156, 93, 280);
        if (id == 101) return (173, 179, 120);
        if (id == 87) return (139, 184, 180);
        if (id == 215) return (189, 157, 110);
        if (id == 42) return (161, 153, 150);
        if (id == 22) return (182, 135, 130);
        if (id == 207) return (143, 204, 130);
        if (id == 24) return (167, 158, 120);
        if (id == 93) return (223, 112, 90);
        if (id == 47) return (165, 146, 120);
        if (id == 20) return (161, 144, 110);
        if (id == 53) return (150, 139, 130);
        if (id == 113) return (60, 176, 500);
        if (id == 198) return (175, 87, 120);
        if (id == 51) return (167, 147, 70);
        if (id == 108) return (108, 137, 180);
        if (id == 190) return (136, 112, 110);
        if (id == 158) return (117, 116, 100);
        if (id == 95) return (85, 288, 70);
        if (id == 1) return (118, 118, 90);
        if (id == 225) return (128, 90, 90);
        if (id == 4) return (116, 96, 78);
        if (id == 155) return (116, 96, 78);
        if (id == 7) return (94, 122, 88);
        if (id == 152) return (92, 122, 90);
        if (id == 25) return (112, 101, 70);
        if (id == 132) return (91, 91, 96);
        if (id == 67) return (177, 130, 160);
        if (id == 64) return (232, 138, 80);
        if (id == 75) return (164, 196, 110);
        if (id == 70) return (172, 95, 130);
        if (id == 180) return (145, 112, 140);
        if (id == 61) return (130, 130, 130);
        if (id == 33) return (137, 112, 122);
        if (id == 30) return (117, 126, 140);
        if (id == 17) return (117, 108, 126);
        if (id == 202) return (60, 106, 380);
        if (id == 188) return (91, 127, 110);
        if (id == 11) return (45, 94, 100);
        if (id == 14) return (46, 86, 90);
        if (id == 235) return (40, 88, 110);
        if (id == 214) return (234, 189, 160);
        if (id == 127) return (238, 197, 130);
        if (id == 124) return (223, 182, 130);
        if (id == 128) return (198, 197, 150);
        if (id == 123) return (218, 170, 140);
        if (id == 226) return (148, 260, 130);
        if (id == 234) return (192, 132, 146);
        if (id == 122) return (192, 233, 80);
        if (id == 211) return (184, 148, 130);
        if (id == 203) return (182, 133, 140);
        if (id == 200) return (167, 167, 120);
        if (id == 206) return (131, 131, 200);
        if (id == 44) return (153, 139, 120);
        if (id == 193) return (154, 94, 130);
        if (id == 222) return (118, 156, 110);
        if (id == 58) return (136, 96, 110);
        if (id == 83) return (124, 118, 104);
        if (id == 35) return (107, 116, 140);
        if (id == 201) return (136, 91, 96);
        if (id == 37) return (96, 122, 76);
        if (id == 218) return (118, 71, 80);
        if (id == 220) return (90, 74, 100);
        if (id == 213) return (17, 396, 40);
        if (id == 114) return (183, 205, 130);
        if (id == 137) return (153, 139, 130);
        if (id == 77) return (170, 132, 100);
        if (id == 138) return (155, 174, 70);
        if (id == 140) return (148, 162, 60);
        if (id == 209) return (137, 89, 120);
        if (id == 228) return (152, 93, 90);
        if (id == 170) return (106, 106, 150);
        if (id == 204) return (108, 146, 100);
        if (id == 92) return (186, 70, 60);
        if (id == 133) return (104, 121, 110);
        if (id == 104) return (90, 165, 100);
        if (id == 177) return (134, 89, 80);
        if (id == 246) return (115, 93, 100);
        if (id == 147) return (119, 94, 82);
        if (id == 46) return (121, 99, 70);
        if (id == 194) return (75, 75, 110);
        if (id == 111) return (140, 157, 160);
        if (id == 98) return (181, 156, 60);
        if (id == 88) return (135, 90, 160);
        if (id == 79) return (109, 109, 180);
        if (id == 66) return (137, 88, 140);
        if (id == 27) return (126, 145, 100);
        if (id == 74) return (132, 163, 80);
        if (id == 216) return (142, 93, 120);
        if (id == 231) return (107, 107, 180);
        if (id == 63) return (195, 103, 50);
        if (id == 102) return (107, 140, 120);
        if (id == 109) return (119, 164, 80);
        if (id == 81) return (165, 128, 50);
        if (id == 84) return (158, 88, 70);
        if (id == 118) return (123, 115, 90);
        if (id == 56) return (148, 87, 80);
        if (id == 96) return (89, 158, 120);
        if (id == 54) return (122, 96, 100);
        if (id == 90) return (116, 168, 60);
        if (id == 72) return (97, 182, 80);
        if (id == 120) return (137, 112, 60);
        if (id == 116) return (129, 125, 60);
        if (id == 69) return (139, 64, 100);
        if (id == 48) return (100, 102, 120);
        if (id == 86) return (85, 128, 130);
        if (id == 179) return (114, 82, 110);
        if (id == 100) return (109, 114, 80);
        if (id == 23) return (110, 102, 70);
        if (id == 223) return (127, 69, 70);
        if (id == 32) return (105, 76, 92);
        if (id == 29) return (86, 94, 110);
        if (id == 39) return (80, 44, 230);
        if (id == 60) return (101, 82, 80);
        if (id == 167) return (105, 73, 80);
        if (id == 21) return (112, 61, 80);
        if (id == 165) return (72, 142, 80);
        if (id == 163) return (67, 101, 120);
        if (id == 52) return (92, 81, 80);
        if (id == 19) return (103, 70, 60);
        if (id == 16) return (85, 76, 80);
        if (id == 41) return (83, 76, 80);
        if (id == 161) return (79, 77, 70);
        if (id == 187) return (67, 101, 70);
        if (id == 50) return (109, 88, 20);
        if (id == 183) return (37, 93, 140);
        if (id == 13) return (63, 55, 80);
        if (id == 10) return (55, 62, 90);
        if (id == 191) return (55, 55, 60);
        if (id == 43) return (131, 116, 90);
        if (id == 129) return (29, 102, 40);
        return (0, 0, 0);

    }

    function sqrt(uint256 x) public pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function maxCP(uint256 genes, uint16 generation) public pure returns (uint32 max_cp) {
        var code = uint8(genes & 0xFF);
        var a = uint32((genes >> 8) & 0xFF);
        var d = uint32((genes >> 16) & 0xFF);
        var s = uint32((genes >> 24) & 0xFF);
 
        var bgColor = uint8((genes >> 33) & 0xFF);
        var (ra, rd, rs) = getBaseStats(code);


        max_cp = uint32(sqrt(uint256(ra + a) * uint256(ra + a) * uint256(rd + d) * uint256(rs + s) * 3900927938993281/10000000000000000 / 100));
        if(max_cp < 10)
            max_cp = 10;

        if(generation < 10)
            max_cp += (10 - generation) * 50;

         
        if(bgColor >= 8)
            bgColor = 0;

        max_cp += bgColor * 25;
        return max_cp;
    }

    function getCode(uint256 genes) pure public returns (uint8) {
        return uint8(genes & 0xFF);
    }

    function getAttack(uint256 genes) pure public returns (uint8) {
        return uint8((genes >> 8) & 0xFF);
    }

    function getDefense(uint256 genes) pure public returns (uint8) {
        return uint8((genes >> 16) & 0xFF);
    }

    function getStamina(uint256 genes) pure public returns (uint8) {
        return uint8((genes >> 24) & 0xFF);
    }

     
     
     
     
    function mixGenes(uint256 genes1, uint256 genes2, uint256 targetBlock) public returns (uint256) {

        uint8 code;
        var r = random(10);

         
        if(r == 0)
            code = getCode(genes1);
        else if(r == 1)
            code = getCode(genes2);
        else
            code = randomCode();

         
        var attack = random(3) == 0 ? uint8(random(32)) : uint8(randomBetween(getAttack(genes1), getAttack(genes2)));
        var defense = random(3) == 0 ? uint8(random(32)) : uint8(randomBetween(getDefense(genes1), getDefense(genes2)));
        var stamina = random(3) == 0 ? uint8(random(32)) : uint8(randomBetween(getStamina(genes1), getStamina(genes2)));
        var gender = uint8(random(2));
        var bgColor = uint8(random(8));
        var rand = random(~uint64(0));

        return uint256(code)  
        | (uint256(attack) << 8)  
        | (uint256(defense) << 16)  
        | (uint256(stamina) << 24)  
        | (uint256(gender) << 32)  
        | (uint256(bgColor) << 33)  
        | (uint256(rand) << 41)  
        ;
    }

    function randomGenes() public returns (uint256) {
        var code = randomCode();
        var attack = uint8(random(32));
        var defense = uint8(random(32));
        var stamina = uint8(random(32));
        var gender = uint8(random(2));
        var bgColor = uint8(random(8));
        var rand = random(~uint64(0));

        return uint256(code)  
        | (uint256(attack) << 8)  
        | (uint256(defense) << 16)  
        | (uint256(stamina) << 24)  
        | (uint256(gender) << 32)  
        | (uint256(bgColor) << 33)  
        | (uint256(rand) << 41)  
        ;
    }
}

 
 
contract SaleClockAuction is ClockAuction {

     
     
    bool public isSaleClockAuction = true;

     
    uint256 public gen0SaleCount;
    uint256[5] public lastGen0SalePrices;

     
    function SaleClockAuction(address _nftAddr, uint256 _cut) public
    ClockAuction(_nftAddr, _cut) {}

     
     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
    external
    {
         
         
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

     
     
    function bid(uint256 _tokenId)
    external
    payable
    {
         
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);

         
        if (seller == address(nonFungibleContract)) {
             
            lastGen0SalePrices[gen0SaleCount % 5] = price;
            gen0SaleCount++;
        }
    }

    function averageGen0SalePrice() external view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < 5; i++) {
            sum += lastGen0SalePrices[i];
        }
        return sum / 5;
    }

}

 
 
contract SiringClockAuction is ClockAuction {

     
     
    bool public isSiringClockAuction = true;

     
    function SiringClockAuction(address _nftAddr, uint256 _cut) public
    ClockAuction(_nftAddr, _cut) {}

     
     
     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
    external
    {
         
         
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

     
     
     
     
    function bid(uint256 _tokenId)
    external
    payable
    {
        require(msg.sender == address(nonFungibleContract));
        address seller = tokenIdToAuction[_tokenId].seller;
         
        _bid(_tokenId, msg.value);
         
         
        _transfer(seller, _tokenId);
    }

}






 
 
 
contract MonsterAccessControl {
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    event ContractUpgrade(address newContract);

     
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

     
    bool public paused = false;

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

     
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

     
     
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

     
     
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

     
     
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

     

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
     
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

     
     
     
     
     
    function unpause() public onlyCEO whenPaused {
         
        paused = false;
    }
}




 
 
 
contract MonsterBase is MonsterAccessControl {
     

     
     
     
    event Birth(address owner, uint256 monsterId, uint256 matronId, uint256 sireId, uint256 genes, uint16 generation);

     
     
    event Transfer(address from, address to, uint256 tokenId);

     

     
     
     
     
     
    struct Monster {
         
         
        uint256 genes;

         
        uint64 birthTime;

         
         
         
        uint64 cooldownEndBlock;

         
         
         
         
         
         
        uint32 matronId;
        uint32 sireId;

         
         
         
         
        uint32 siringWithId;

         
         
         
         
         
        uint16 cooldownIndex;

         
         
         
         
         
        uint16 generation;
    }

     

     
     
     
     
     
     
    uint32[14] public cooldowns = [
    uint32(1 minutes),
    uint32(2 minutes),
    uint32(5 minutes),
    uint32(10 minutes),
    uint32(30 minutes),
    uint32(1 hours),
    uint32(2 hours),
    uint32(4 hours),
    uint32(8 hours),
    uint32(16 hours),
    uint32(1 days),
    uint32(2 days),
    uint32(4 days),
    uint32(7 days)
    ];

     
    uint256 public secondsPerBlock = 15;

     

     
     
     
     
     
    Monster[] monsters;

     
     
    mapping(uint256 => address) public monsterIndexToOwner;

     
     
    mapping(address => uint256) ownershipTokenCount;

     
     
     
    mapping(uint256 => address) public monsterIndexToApproved;

     
     
     
    mapping(uint256 => address) public sireAllowedToAddress;

     
     
     
    SaleClockAuction public saleAuction;

     
     
     
    SiringClockAuction public siringAuction;

    GeneScience public geneScience;

     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
         
        ownershipTokenCount[_to]++;
         
        monsterIndexToOwner[_tokenId] = _to;

         
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
             
            delete sireAllowedToAddress[_tokenId];
             
            delete monsterIndexToApproved[_tokenId];
        }
         
        Transfer(_from, _to, _tokenId);
    }

     
     
     
     
     
     
     
     
     
    function _createMonster(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    )
    internal
    returns (uint)
    {
         
         
         
         
        require(_matronId == uint256(uint32(_matronId)));
        require(_sireId == uint256(uint32(_sireId)));
        require(_generation == uint256(uint16(_generation)));

         
        uint16 cooldownIndex = uint16(_generation / 2);
        if (cooldownIndex > 13) {
            cooldownIndex = 13;
        }

        Monster memory _monster = Monster({
            genes : _genes,
            birthTime : uint64(now),
            cooldownEndBlock : 0,
            matronId : uint32(_matronId),
            sireId : uint32(_sireId),
            siringWithId : 0,
            cooldownIndex : cooldownIndex,
            generation : uint16(_generation)
            });
        uint256 newKittenId = monsters.push(_monster) - 1;

         
         
        require(newKittenId == uint256(uint32(newKittenId)));

         
        Birth(
            _owner,
            newKittenId,
            uint256(_monster.matronId),
            uint256(_monster.sireId),
            _monster.genes,
            uint16(_generation)
        );

         
         
        _transfer(0, _owner, newKittenId);

        return newKittenId;
    }

     
    function setSecondsPerBlock(uint256 secs) external onlyCLevel {
        require(secs < cooldowns[0]);
        secondsPerBlock = secs;
    }
}





 
 
contract ERC721Metadata {
     
    function getMetadata(uint256 _tokenId, string) public view returns (bytes32[4] buffer, uint256 count) {
        if (_tokenId == 1) {
            buffer[0] = "Hello World! :D";
            count = 15;
        } else if (_tokenId == 2) {
            buffer[0] = "I would definitely choose a medi";
            buffer[1] = "um length string.";
            count = 49;
        } else if (_tokenId == 3) {
            buffer[0] = "Lorem ipsum dolor sit amet, mi e";
            buffer[1] = "st accumsan dapibus augue lorem,";
            buffer[2] = " tristique vestibulum id, libero";
            buffer[3] = " suscipit varius sapien aliquam.";
            count = 128;
        }
    }
}


 
 
 
 
contract MonsterOwnership is MonsterBase, ERC721 {

     
    string public constant name = "Ethermon";
    string public constant symbol = "EM";

     
    ERC721Metadata public erc721Metadata;

    bytes4 constant InterfaceSignature_ERC165 =
    bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 constant InterfaceSignature_ERC721 =
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('ownerOf(uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('transfer(address,uint256)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('tokensOfOwner(address)')) ^
    bytes4(keccak256('tokenMetadata(uint256,string)'));

     
     
     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
         
         

        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

     
     
    function setMetadataAddress(address _contractAddress) public onlyCEO {
        erc721Metadata = ERC721Metadata(_contractAddress);
    }

     
     
     

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return monsterIndexToOwner[_tokenId] == _claimant;
    }

     
     
     
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return monsterIndexToApproved[_tokenId] == _claimant;
    }

     
     
     
     
     
    function _approve(uint256 _tokenId, address _approved) internal {
        monsterIndexToApproved[_tokenId] = _approved;
    }

     
     
     
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

     
     
     
     
     
     
    function transfer(
        address _to,
        uint256 _tokenId
    )
    external
    whenNotPaused
    {
         
        require(_to != address(0));
         
         
         
        require(_to != address(this));
         
         
         
        require(_to != address(saleAuction));
        require(_to != address(siringAuction));

         
        require(_owns(msg.sender, _tokenId));

             
        _transfer(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
    function approve(
        address _to,
        uint256 _tokenId
    )
    external
    whenNotPaused
    {
         
        require(_owns(msg.sender, _tokenId));

         
        _approve(_tokenId, _to);

         
        Approval(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
    external
    whenNotPaused
    {
         
        require(_to != address(0));
         
         
         
        require(_to != address(this));
         
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

         
        _transfer(_from, _to, _tokenId);
    }

     
     
    function totalSupply() public view returns (uint) {
        return monsters.length - 1;
    }

     
     
    function ownerOf(uint256 _tokenId)
    external
    view
    returns (address owner)
    {
        owner = monsterIndexToOwner[_tokenId];

        require(owner != address(0));
    }

     
     
     
     
     
     
    function tokensOfOwner(address _owner) external view returns (uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalMonsters = totalSupply();
            uint256 resultIndex = 0;

             
             
            uint256 monsterId;

            for (monsterId = 1; monsterId <= totalMonsters; monsterId++) {
                if (monsterIndexToOwner[monsterId] == _owner) {
                    result[resultIndex] = monsterId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

     
     
     
    function _memcpy(uint _dest, uint _src, uint _len) private view {
         
        for (; _len >= 32; _len -= 32) {
            assembly {
                mstore(_dest, mload(_src))
            }
            _dest += 32;
            _src += 32;
        }

         
        uint256 mask = 256 ** (32 - _len) - 1;
        assembly {
            let srcpart := and(mload(_src), not(mask))
            let destpart := and(mload(_dest), mask)
            mstore(_dest, or(destpart, srcpart))
        }
    }

     
     
     
    function _toString(bytes32[4] _rawBytes, uint256 _stringLength) private view returns (string) {
        var outputString = new string(_stringLength);
        uint256 outputPtr;
        uint256 bytesPtr;

        assembly {
            outputPtr := add(outputString, 32)
            bytesPtr := _rawBytes
        }

        _memcpy(outputPtr, bytesPtr, _stringLength);

        return outputString;
    }

     
     
     
    function tokenMetadata(uint256 _tokenId, string _preferredTransport) external view returns (string infoUrl) {
        require(erc721Metadata != address(0));
        bytes32[4] memory buffer;
        uint256 count;
        (buffer, count) = erc721Metadata.getMetadata(_tokenId, _preferredTransport);

        return _toString(buffer, count);
    }
}



 
 
 
contract MonsterBreeding is MonsterOwnership {

     
     
    event Pregnant(address owner, uint256 matronId, uint256 sireId, uint256 cooldownEndBlock);

     
     
     
    uint256 public autoBirthFee = 8 finney;

     
    uint256 public pregnantMonsters;

     
     

     
     
    function setGeneScienceAddress(address _address) external onlyCEO {
        GeneScience candidateContract = GeneScience(_address);

        require(candidateContract.isGeneScience());

         
        geneScience = candidateContract;
    }

     
     
     
    function _isReadyToBreed(Monster _monster) internal view returns (bool) {
         
         
         
        return (_monster.siringWithId == 0) && (_monster.cooldownEndBlock <= uint64(block.number));
    }

     
     
     
    function _isSiringPermitted(uint256 _sireId, uint256 _matronId) internal view returns (bool) {
        address matronOwner = monsterIndexToOwner[_matronId];
        address sireOwner = monsterIndexToOwner[_sireId];

         
         
        return (matronOwner == sireOwner || sireAllowedToAddress[_sireId] == matronOwner);
    }

     
     
     
    function _triggerCooldown(Monster storage _monster) internal {
         
        _monster.cooldownEndBlock = uint64((cooldowns[_monster.cooldownIndex] / secondsPerBlock) + block.number);

         
         
         
        if (_monster.cooldownIndex < 13) {
            _monster.cooldownIndex += 1;
        }
    }

     
     
     
     
     
    function approveSiring(address _addr, uint256 _sireId)
    external
    whenNotPaused
    {
        require(_owns(msg.sender, _sireId));
        sireAllowedToAddress[_sireId] = _addr;
    }

     
     
     
    function setAutoBirthFee(uint256 val) external onlyCOO {
        autoBirthFee = val;
    }

     
     
    function _isReadyToGiveBirth(Monster _matron) private view returns (bool) {
        return (_matron.siringWithId != 0) && (_matron.cooldownEndBlock <= uint64(block.number));
    }

     
     
     
    function isReadyToBreed(uint256 _monsterId)
    public
    view
    returns (bool)
    {
        require(_monsterId > 0);
        Monster storage monster = monsters[_monsterId];
        return _isReadyToBreed(monster);
    }

     
     
    function isPregnant(uint256 _monsterId)
    public
    view
    returns (bool)
    {
        require(_monsterId > 0);
         
        return monsters[_monsterId].siringWithId != 0;
    }

     
     
     
     
     
     
    function _isValidMatingPair(
        Monster storage _matron,
        uint256 _matronId,
        Monster storage _sire,
        uint256 _sireId
    )
    private
    view
    returns (bool)
    {
         
        if (_matronId == _sireId) {
            return false;
        }

         
        if (_matron.matronId == _sireId || _matron.sireId == _sireId) {
            return false;
        }
        if (_sire.matronId == _matronId || _sire.sireId == _matronId) {
            return false;
        }

         
         
        if (_sire.matronId == 0 || _matron.matronId == 0) {
            return true;
        }

         
        if (_sire.matronId == _matron.matronId || _sire.matronId == _matron.sireId) {
            return false;
        }
        if (_sire.sireId == _matron.matronId || _sire.sireId == _matron.sireId) {
            return false;
        }

         
        return true;
    }

     
     
    function _canBreedWithViaAuction(uint256 _matronId, uint256 _sireId)
    internal
    view
    returns (bool)
    {
        Monster storage matron = monsters[_matronId];
        Monster storage sire = monsters[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId);
    }

     
     
     
     
     
     
    function canBreedWith(uint256 _matronId, uint256 _sireId)
    external
    view
    returns (bool)
    {
        require(_matronId > 0);
        require(_sireId > 0);
        Monster storage matron = monsters[_matronId];
        Monster storage sire = monsters[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId) &&
        _isSiringPermitted(_sireId, _matronId);
    }

     
     
    function _breedWith(uint256 _matronId, uint256 _sireId) internal {
         
        Monster storage sire = monsters[_sireId];
        Monster storage matron = monsters[_matronId];

         
        matron.siringWithId = uint32(_sireId);

         
        _triggerCooldown(sire);
        _triggerCooldown(matron);

         
         
        delete sireAllowedToAddress[_matronId];
        delete sireAllowedToAddress[_sireId];

         
        pregnantMonsters++;

         
        Pregnant(monsterIndexToOwner[_matronId], _matronId, _sireId, matron.cooldownEndBlock);
    }

     
     
     
     
     
    function breedWithAuto(uint256 _matronId, uint256 _sireId)
    external
    payable
    whenNotPaused
    {
         
        require(msg.value >= autoBirthFee);

         
        require(_owns(msg.sender, _matronId));

         
         
         
         
         
         
         
         
         
         

         
         
         
        require(_isSiringPermitted(_sireId, _matronId));

         
        Monster storage matron = monsters[_matronId];

         
        require(_isReadyToBreed(matron));

         
        Monster storage sire = monsters[_sireId];

         
        require(_isReadyToBreed(sire));

         
        require(_isValidMatingPair(
                matron,
                _matronId,
                sire,
                _sireId
            ));

         
        _breedWith(_matronId, _sireId);
    }

     
     
     
     
     
     
     
     
    function giveBirth(uint256 _matronId)
    external
    onlyCOO
    whenNotPaused
    returns (uint256)
    {
         
        Monster storage matron = monsters[_matronId];

         
        require(matron.birthTime != 0);

         
        require(_isReadyToGiveBirth(matron));

         
        uint256 sireId = matron.siringWithId;
        Monster storage sire = monsters[sireId];

         
        uint16 parentGen = matron.generation;
        if (sire.generation > matron.generation) {
            parentGen = sire.generation;
        }

         
         
        uint256 childGenes = geneScience.mixGenes(matron.genes, sire.genes, matron.cooldownEndBlock - 1);

         
        address owner = monsterIndexToOwner[_matronId];
        uint256 monsterId = _createMonster(_matronId, matron.siringWithId, parentGen + 1, childGenes, owner);

         
         
        delete matron.siringWithId;

         
        pregnantMonsters--;

         
        msg.sender.send(autoBirthFee);

         
        return monsterId;
    }
}












 
 
 
contract MonsterAuction is MonsterBreeding {

     
     
     
     

     
     
    function setSaleAuctionAddress(address _address) external onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

         
        require(candidateContract.isSaleClockAuction());

         
        saleAuction = candidateContract;
    }

     
     
    function setSiringAuctionAddress(address _address) external onlyCEO {
        SiringClockAuction candidateContract = SiringClockAuction(_address);

         
        require(candidateContract.isSiringClockAuction());

         
        siringAuction = candidateContract;
    }

     
     
    function createSaleAuction(
        uint256 _monsterId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
    external
    whenNotPaused
    {
         
         
         
        require(_owns(msg.sender, _monsterId));
         
         
         
        require(!isPregnant(_monsterId));
        _approve(_monsterId, saleAuction);
         
         
        saleAuction.createAuction(
            _monsterId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

     
     
     
    function createSiringAuction(
        uint256 _monsterId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
    external
    whenNotPaused
    {
         
         
         
        require(_owns(msg.sender, _monsterId));
        require(isReadyToBreed(_monsterId));
        _approve(_monsterId, siringAuction);
         
         
        siringAuction.createAuction(
            _monsterId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

     
     
     
     
    function bidOnSiringAuction(
        uint256 _sireId,
        uint256 _matronId
    )
    external
    payable
    whenNotPaused
    {
         
        require(_owns(msg.sender, _matronId));
        require(isReadyToBreed(_matronId));
        require(_canBreedWithViaAuction(_matronId, _sireId));

         
        uint256 currentPrice = siringAuction.getCurrentPrice(_sireId);
        require(msg.value >= currentPrice + autoBirthFee);

         
        siringAuction.bid.value(msg.value - autoBirthFee)(_sireId);
        _breedWith(uint32(_matronId), uint32(_sireId));
    }

     
     
     
    function withdrawAuctionBalances() external onlyCLevel {
        saleAuction.withdrawBalance();
        siringAuction.withdrawBalance();
    }
}


 
contract MonsterMinting is MonsterAuction {

     
    uint256 public constant PROMO_CREATION_LIMIT = 5000;
    uint256 public constant GEN0_CREATION_LIMIT = 45000;

     
    uint256 public constant GEN0_STARTING_PRICE = 10 finney;
    uint256 public constant GEN0_AUCTION_DURATION = 1 days;

     
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;

     
     
     
    function createPromoMonster(uint256 _genes, address _owner) external onlyCOO {
        address monsterOwner = _owner;
        if (monsterOwner == address(0)) {
            monsterOwner = cooAddress;
        }
        require(promoCreatedCount < PROMO_CREATION_LIMIT);

        promoCreatedCount++;
        _createMonster(0, 0, 0, _genes, monsterOwner);
    }

     
     
    function createGen0Auction(uint256 _genes) external onlyCOO {
        require(gen0CreatedCount < GEN0_CREATION_LIMIT);

        uint256 genes = _genes;
        if(genes == 0)
            genes = geneScience.randomGenes();

        uint256 monsterId = _createMonster(0, 0, 0, genes, address(this));
        _approve(monsterId, saleAuction);

        saleAuction.createAuction(
            monsterId,
            _computeNextGen0Price(),
            0,
            GEN0_AUCTION_DURATION,
            address(this)
        );

        gen0CreatedCount++;
    }

     
     
    function _computeNextGen0Price() internal view returns (uint256) {
        uint256 avePrice = saleAuction.averageGen0SalePrice();

         
        require(avePrice == uint256(uint128(avePrice)));

        uint256 nextPrice = avePrice + (avePrice / 2);

         
        if (nextPrice < GEN0_STARTING_PRICE) {
            nextPrice = GEN0_STARTING_PRICE;
        }

        return nextPrice;
    }
}


 
 
 
contract MonsterCore is MonsterMinting {

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    address public newContractAddress;

     
    function MonsterCore() public {
         
        paused = false;

         
        ceoAddress = msg.sender;

         
        cooAddress = msg.sender;

         
        cfoAddress = msg.sender;

         
        _createMonster(0, 0, 0, uint256(57896044618658097711785492504343953926634992332820282019728792004021511462807), address(0));
    }

     
     
     
     
     
     
    function setNewAddress(address _v2Address) external onlyCEO whenPaused {
         
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

     
     
     
    function() external payable {
        require(
            msg.sender == address(saleAuction) ||
            msg.sender == address(siringAuction)
        );
    }

     
     
    function getMonster(uint256 _id)
    external
    view
    returns (
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256 genes
    ) {
        Monster storage monster = monsters[_id];

         
        isGestating = (monster.siringWithId != 0);
        isReady = (monster.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(monster.cooldownIndex);
        nextActionAt = uint256(monster.cooldownEndBlock);
        siringWithId = uint256(monster.siringWithId);
        birthTime = uint256(monster.birthTime);
        matronId = uint256(monster.matronId);
        sireId = uint256(monster.sireId);
        generation = uint256(monster.generation);
        genes = monster.genes;
    }

     
     
     
     
     
    function unpause() public onlyCEO whenPaused {
        require(saleAuction != address(0));
        require(siringAuction != address(0));
        require(geneScience != address(0));
        require(newContractAddress == address(0));

         
        super.unpause();
    }

     
    function withdrawBalance() external onlyCFO {
        uint256 balance = this.balance;
         
        uint256 subtractFees = (pregnantMonsters + 1) * autoBirthFee;

        if (balance > subtractFees) {
            cfoAddress.send(balance - subtractFees);
        }
    }
}