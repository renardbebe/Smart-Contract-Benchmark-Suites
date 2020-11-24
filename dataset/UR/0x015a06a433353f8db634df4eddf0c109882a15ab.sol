 

pragma solidity ^0.4.2;
contract PixelMap {
    address creator;
    struct Tile {
        address owner;
        string image;
        string url;
        uint price;
    }
    mapping (uint => Tile) public tiles;
    event TileUpdated(uint location);

     
    function PixelMap() {creator = msg.sender;}

     
    function getTile(uint location) returns (address, string, string, uint) {
        return (tiles[location].owner,
                tiles[location].image,
                tiles[location].url,
                tiles[location].price);
    }

     
    function buyTile(uint location) payable {
        if (location > 3969) {throw;}
        uint price = tiles[location].price;
        address owner;

         
        if (tiles[location].owner == msg.sender) {
            throw;
        }

         
        if (tiles[location].owner == 0x0) {
            price = 2000000000000000000;
            owner = creator;
        }
        else {
            owner = tiles[location].owner;
        }
         
        if (price == 0) {
            throw;
        }

         
        if (msg.value != price) {
            throw;
        }
        if (owner.send(price)) {
            tiles[location].owner = msg.sender;
            tiles[location].price = 0;  
            TileUpdated(location);
        }
        else {throw;}
    }

     
    function setTile(uint location, string image, string url, uint price) {
        if (tiles[location].owner != msg.sender) {throw;}  
        else {
            tiles[location].image = image;
            tiles[location].url = url;
            tiles[location].price = price;
            TileUpdated(location);
        }
    }
}