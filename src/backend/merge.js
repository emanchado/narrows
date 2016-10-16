export default function merge(dst) {
    const origins = Array.prototype.slice.call(arguments, 1);

    origins.forEach(obj => {
        Object.keys(obj).forEach(key => {
            dst[key] = obj[key];
        });
    });

    return dst;
}
