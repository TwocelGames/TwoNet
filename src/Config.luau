--!strict

return table.freeze{

	-- The default size of the networking buffer (should be greater than the largest amount of data you might send as long as the said data is not too big >2-3kb)
	-- if the size is too high uneccesary memory will be reserved
	BUFFER_START_SIZE = 128,

	-- The scale factor for buffer when u try to pass in data greater than the said amount. (ie if ur buf is 100b and u pass in 150, 100*scalefactor = newbuffersize)
	BUFFER_SCALE_FACTOR = 2,

	-- The amount the scale factor should be decreased after each increase this to ensure buffers don't get too large (ie after first scale scalefactor -= (scalefactor - 1) * brake)
	BUFFER_SCALE_BRAKE = 0.2,

	-- Buffer header is the numerical data type used to store the size of objects like strings/buffers 
	-- The write and read methods must match & the size must be the size of the data written by those methods
	-- The Max header size is the biggest number the header can hold.
	BUFFER_HEADER_WRITE = buffer.writeu16,
	BUFFER_HEADER_READ = buffer.readu16,
	BUFFER_HEADER_LENGTH = 2,
	MAX_HEADER_DATA = 2 ^ 16,
	
	-- The maximum number that can be used as a packet id ( > value u means u can create more packets)
	-- greater value will increase the payload size since we will have to use larger datatypes to write packetId and count	
	MAX_PACKET_ID = 2 ^ 8,

	-- Max items in array works similar to max packets
	MAX_ARRAY_INDEX = 2 ^ 16,

}