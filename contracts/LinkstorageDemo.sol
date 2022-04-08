// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

contract LinkstorageDemo is ChainlinkClient, Ownable, Pausable {
    using Chainlink for Chainlink.Request;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    struct LinkData {
        string id;
        string base16Cid;
    }
    mapping(bytes32 => LinkData) public links;

    event StorageRequestSent(address indexed addr, bytes32 indexed reqID, string indexed id);
    event StorageRequestFulfilled(bytes32 indexed reqID, bytes32 indexed base16Cid, string indexed id);

    constructor() {
        setPublicChainlinkToken();
        oracle = 0xA7b2bb8B5ba870Fb1Db63F54aE7F73fcfb9F8C52;
        jobId = "0958814163394e14afca5f5dba90eec5";
        fee = 0.1 * 10 ** 18; // 0.1 LINK
    }

    function stateUpdateAndSaveToIPFS(
        string memory _id,
        string memory _val1,
        string memory _val2,
        string memory _val3
    ) public whenNotPaused payable returns (bytes32) {
        // TODO: add your logic here
        console.log("State updating...");

        // Build Chainlink Request
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        req.add("msgSender", Strings.toHexString(uint256(uint160(msg.sender)), 20));
        req.add("key1", _val1);
        req.add("key2", _val2);
        req.add("key3", _val3);
        bytes32 requestID = sendChainlinkRequestTo(oracle, req, fee);
        
        // You can link the above requestID to the STRUCT or Mapping state
        LinkData storage ld = links[requestID];
        ld.id = _id;

        emit StorageRequestSent(_msgSender(), requestID, _id);
        return requestID;
    }

    /**
     * Chainlink Oracle callback function
     */
    function fulfill(
        bytes32 _requestId,
        bytes32 _base16Cid
    ) public recordChainlinkFulfillment(_requestId) {
        LinkData storage ld = links[_requestId];
        ld.base16Cid = toBase16CID(_base16Cid);

        // TODO: You could do more thing here based on the data id or cid

        // You can watch this event in your app to get the corresponding data for a paticular wallet address.
        emit StorageRequestFulfilled(_requestId, _base16Cid, ld.id);

        // Your can remove the request id map from the links
        // delete links[_requestId];
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }

    function setJobId(bytes32 _jobId) external onlyOwner {
        jobId = _jobId;
    }

    function setOracleFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function getBase16CidByRequestId(bytes32 _reqID) external view returns (string memory) {
        return links[_reqID].base16Cid;
    }

    /// Withdraw the LINK tokens from this contract to avoid locking them here.
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.balanceOf(address(this)) > 0, "Insufficient LINK left!");
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

    function toBase16CID(bytes32 data) internal pure returns (string memory) {
        return string(abi.encodePacked("f", toHex16(bytes16(data)), toHex16(bytes16(data << 128))));
    }

    /**
     * Convert bytes16 data to bytes32.
     * https://stackoverflow.com/questions/67893318/solidity-how-to-represent-bytes32-as-string
     */
    function toHex16(bytes16 data) internal pure returns (bytes32 result) {
        result = bytes32(data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 |
            (bytes32(data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64;
        result = result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000 |
            (result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32;
        result = result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000 |
            (result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16;
        result = result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000 |
            (result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8;
        result = (result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4 |
            (result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8;
        result = bytes32(0x3030303030303030303030303030303030303030303030303030303030303030 +
            uint256(result) +
            (uint256(result) + 0x0606060606060606060606060606060606060606060606060606060606060606 >> 4 &
            0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) * 39);
    }

}
